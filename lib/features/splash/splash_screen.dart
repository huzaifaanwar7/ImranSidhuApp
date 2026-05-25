import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Stack(
        children: [
          // Background gradient + gold orb
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  AppColors.navyLight,
                  AppColors.navy,
                  AppColors.navyDeep
                ],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
          // Soft gold glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
            ),
          ),
          // Vertical pinstripes
          Positioned.fill(
            child: CustomPaint(painter: _StripePainter()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 60, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text('ESTABLISHED IN HIS MEMORY',
                      style: AppTextStyles.mono(
                        size: 10,
                        color: AppColors.goldBright,
                        letterSpacing: 0.4,
                      )),
                  const SizedBox(height: 24),
                  // Dashed gold ring around logo
                  CustomPaint(
                    painter: _DashedRingPainter(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: AppLogo(size: 180, showLabel: false),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Cricket. Heritage. Honour.',
                      style: AppTextStyles.italicAccent(
                          size: 15,
                          color: AppColors.cream.withValues(alpha: 0.75))),
                  const SizedBox(height: 24),
                  // Loader bar
                  Container(
                    width: 80,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, __) => FractionallySizedBox(
                          widthFactor: _ctrl.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Sponsors row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('IN ASSOCIATION WITH',
                            style: AppTextStyles.mono(
                              size: 9,
                              color: AppColors.gold.withValues(alpha: 0.7),
                              letterSpacing: 0.3,
                            )),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _miniSponsor(
                                  'Amas',
                                  AppAssets.amasLogo,
                                  'FEEL THE DIFFERENCE',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.line,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              Expanded(
                                child: _miniSponsor(
                                  'PM Sports',
                                  AppAssets.pmSportsLogo,
                                  'SUBLIMATION SHIRT MAKER',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniSponsor(String name, String logoAsset, String tagline) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.line),
          ),
          child: Image.asset(
            logoAsset,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.fraunces(size: 11, weight: FontWeight.w700),
              ),
              Text(
                tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.mono(size: 6, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashLen = 6.0;
    const gapLen = 4.0;
    final circumference = 2 * 3.14159 * radius;
    final dashCount = (circumference / (dashLen + gapLen)).floor();
    final sweep = (dashLen / radius);
    final gap = (gapLen / radius);
    var start = 0.0;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
