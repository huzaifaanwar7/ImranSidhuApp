import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// VCC roundel used across the app chrome, auth screens, and splash screen.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showLabel;
  final bool onLightBg;

  const AppLogo({
    super.key,
    this.size = 96,
    this.showLabel = false,
    this.onLightBg = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.25),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.06),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            AppAssets.vccLogo,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackLogo(size),
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: size * 0.18),
          Text(
            'Imran Sidhu',
            style: AppTextStyles.fraunces(
                size: size * 0.18,
                weight: FontWeight.w900,
                color: onLightBg ? AppColors.navyDeep : AppColors.cream),
          ),
          Text(
            'Memorial VCC',
            style: AppTextStyles.italicAccent(
                size: size * 0.14, color: AppColors.goldDeep),
          ),
        ],
      ],
    );
  }

  Widget _fallbackLogo(double size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.navyGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.sports_cricket_rounded,
            size: size * 0.42,
            color: AppColors.gold,
          ),
          Positioned(
            bottom: size * 0.16,
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: const BoxDecoration(
                color: AppColors.ballRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.1,
            child: Text(
              'IMRAN SIDHU',
              style: AppTextStyles.bebas(
                size: size * 0.085,
                color: AppColors.cream,
                letterSpacing: 0.18,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.05,
            child: Text(
              'MEMORIAL VCC',
              style: AppTextStyles.mono(
                size: size * 0.06,
                color: AppColors.goldBright,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
