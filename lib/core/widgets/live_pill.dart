import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LivePill extends StatefulWidget {
  final String label;
  const LivePill({super.key, this.label = 'LIVE NOW'});

  @override
  State<LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.ballRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.3 + 0.7 * _c.value,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(widget.label,
                style: AppTextStyles.mono(
                  size: 9,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                )),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.mono(
            size: 8,
            weight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          )),
    );
  }
}
