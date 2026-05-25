import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';

class TossScreen extends StatefulWidget {
  final String homeId;
  final String awayId;
  const TossScreen({super.key, required this.homeId, required this.awayId});

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  String? winnerId;
  TossDecision? decision;

  void _flip() {
    setState(() => winnerId = null);
    _ctrl.forward(from: 0).then((_) {
      setState(() {
        winnerId = Random().nextBool() ? widget.homeId : widget.awayId;
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = MockData.teamById(widget.homeId);
    final away = MockData.teamById(widget.awayId);
    final w = winnerId == null ? null : MockData.teamById(winnerId!);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'The', italic: 'Toss'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('TAP THE COIN TO FLIP',
                      style: AppTextStyles.mono(
                          size: 9, letterSpacing: 0.25, color: AppColors.grey)),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _flip,
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_ctrl.value * 8 * pi),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              center: Alignment(-0.3, -0.3),
                              colors: [
                                AppColors.goldBright,
                                AppColors.gold,
                                AppColors.goldDeep
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            w == null ? 'VCC' : w.shortCode,
                            style: AppTextStyles.bebas(
                                size: 38, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (w != null) ...[
                    Text('${w.name} wins the toss',
                        style: AppTextStyles.headlineLarge),
                    Text('Choose their decision',
                        style: AppTextStyles.italicAccent(
                            size: 13, color: AppColors.grey)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                            child: _dec(TossDecision.bat, 'Bat first',
                                Icons.sports_cricket_rounded)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _dec(TossDecision.bowl, 'Bowl first',
                                Icons.shield_outlined)),
                      ],
                    ),
                  ] else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TeamBadge(team: home, size: 56),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('VS',
                              style: AppTextStyles.bebas(
                                  size: 22, color: AppColors.grey)),
                        ),
                        TeamBadge(team: away, size: 56),
                      ],
                    ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Continue to Playing XI',
                    onPressed: winnerId == null || decision == null
                        ? null
                        : () => context.push('/match/new/playing-xi', extra: {
                              'home': widget.homeId,
                              'away': widget.awayId,
                            }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dec(TossDecision d, String label, IconData icon) {
    final selected = decision == d;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => decision = d),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.navyDeep : AppColors.line,
              width: 1.4),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.gold : AppColors.navyDeep,
                size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.fraunces(
                    size: 13,
                    weight: FontWeight.w700,
                    color: selected ? AppColors.cream : AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
