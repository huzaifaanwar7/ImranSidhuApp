import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';

class _Slide {
  final IconData icon;
  final String title;
  final String italic;
  final String body;
  const _Slide(this.icon, this.title, this.italic, this.body);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  static const _slides = [
    _Slide(Icons.sports_cricket_rounded, 'Ball-by-ball', 'scoring',
        'Record every legal and illegal delivery with full undo and offline support.'),
    _Slide(Icons.emoji_events_outlined, 'Run leagues', 'your way',
        'Round-robin, knockouts and hybrids — auto-generated fixtures, live standings, NRR & brackets.'),
    _Slide(Icons.bar_chart_rounded, 'Career &', 'live stats',
        'Strike rate, economy, partnerships, milestones — refreshed after every ball.'),
    _Slide(Icons.share_rounded, 'Share', 'the moment',
        'WhatsApp-ready cards, PNG scorecards and PDF exports in a single tap.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('SKIP'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (i) => setState(() => _i = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.12),
                          ),
                          child:
                              Icon(s.icon, size: 80, color: AppColors.navyDeep),
                        ),
                        const SizedBox(height: 40),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(children: [
                            TextSpan(
                                text: '${s.title} ',
                                style: AppTextStyles.fraunces(
                                    size: 28,
                                    weight: FontWeight.w900,
                                    color: AppColors.navyDeep)),
                            TextSpan(
                                text: s.italic,
                                style: AppTextStyles.italicAccent(
                                    size: 28, color: AppColors.goldDeep)),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        Text(s.body,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.fraunces(
                                size: 14,
                                weight: FontWeight.w400,
                                color: AppColors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _i == i ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _i == i ? AppColors.gold : AppColors.line,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: _i == _slides.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_i == _slides.length - 1) {
                    context.go('/login');
                  } else {
                    _pc.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
