import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_logo.dart';

/// In-app top bar with mini logo + icon button(s).
class AppTopBar extends StatelessWidget {
  final List<Widget>? actions;
  const AppTopBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: AppLogo(size: 38, showLabel: false),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('IMRAN SIDHU',
                  style: AppTextStyles.bebas(
                    size: 13,
                    color: AppColors.navyDeep,
                    letterSpacing: 0.08,
                  )),
              Text('MEMORIAL VCC',
                  style: AppTextStyles.mono(
                    size: 7,
                    color: AppColors.goldDeep,
                    letterSpacing: 0.25,
                  )),
            ],
          ),
          const Spacer(),
          ...?actions,
        ],
      ),
    );
  }
}

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? color;
  final bool dot;

  const IconBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.bg,
    this.color,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg ?? AppColors.navy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: color ?? AppColors.navyDeep),
          ),
          if (dot)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cream, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BackBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? italic;
  final List<Widget>? actions;
  final Color background;
  final Color foreground;

  const BackBar({
    super.key,
    required this.title,
    this.italic,
    this.actions,
    this.background = AppColors.navyDeep,
    this.foreground = AppColors.cream,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_rounded,
                          size: 14, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text('BACK',
                          style: AppTextStyles.mono(
                            size: 9,
                            color: AppColors.gold,
                            letterSpacing: 0.25,
                            weight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
                const Spacer(),
                ...?actions,
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: title,
                  style: AppTextStyles.fraunces(
                      size: 24, weight: FontWeight.w900, color: foreground),
                ),
                if (italic != null)
                  TextSpan(
                    text: ' $italic',
                    style: AppTextStyles.italicAccent(
                        size: 24, color: AppColors.gold),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
