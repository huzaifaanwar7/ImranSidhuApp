import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';

class SponsorsScreen extends StatelessWidget {
  const SponsorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sponsors = MockData.sponsors;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'Our', italic: 'Sponsors'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              children: [
                const _SponsorFeatureCard(
                  category: 'TITLE SPONSOR',
                  name: 'Amas',
                  tagline: 'Feel The Difference',
                  description:
                      'Premium quality apparel and lifestyle brand, title partner of the Imran Sidhu Memorial VCC.',
                  imageAsset: AppAssets.amasLogo,
                  imageHeight: 92,
                ),
                const SizedBox(height: 14),
                const _SponsorFeatureCard(
                  category: 'KIT SPONSOR',
                  name: 'PM Sports Hosiery',
                  tagline: 'Sublimation Shirt Maker',
                  description:
                      'Custom sublimation kits and team apparel for all participating squads.',
                  imageAsset: AppAssets.pmSportsLogo,
                  imageHeight: 118,
                  phone: '0307-7590838',
                ),
                const SizedBox(height: 18),
                Text(
                  'SLOT ASSIGNMENTS',
                  style: AppTextStyles.mono(
                    size: 9,
                    color: AppColors.grey,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                for (final s in sponsors)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        _SponsorThumb(path: s.logoUrl, name: s.name),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: AppTextStyles.fraunces(
                                  size: 13,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: s.slots
                                    .map(
                                      (slot) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          slot.label.toUpperCase(),
                                          style: AppTextStyles.mono(
                                            size: 8,
                                            color: AppColors.goldDeep,
                                            letterSpacing: 0.15,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: s.isActive,
                          onChanged: (_) {},
                          activeThumbColor: AppColors.navyDeep,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorFeatureCard extends StatelessWidget {
  final String category;
  final String name;
  final String tagline;
  final String description;
  final String imageAsset;
  final double imageHeight;
  final String? phone;

  const _SponsorFeatureCard({
    required this.category,
    required this.name,
    required this.tagline,
    required this.description,
    required this.imageAsset,
    required this.imageHeight,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF8EE), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: imageHeight,
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            category,
            style: AppTextStyles.mono(
              size: 9,
              color: AppColors.goldDeep,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: AppTextStyles.fraunces(
              size: 22,
              weight: FontWeight.w700,
              color: AppColors.navyDeep,
            ),
          ),
          Text(
            tagline,
            style: AppTextStyles.italicAccent(
              size: 13,
              color: AppColors.ballRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.fraunces(
              size: 12,
              weight: FontWeight.w400,
              color: AppColors.grey,
            ),
          ),
          if (phone != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyDeep,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone_in_talk_rounded,
                    color: AppColors.gold,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    phone!,
                    style: AppTextStyles.mono(
                      size: 9,
                      color: AppColors.gold,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SponsorThumb extends StatelessWidget {
  final String? path;
  final String name;

  const _SponsorThumb({required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: path == null
          ? Center(
              child: Text(
                name.substring(0, 1),
                style: AppTextStyles.bebas(size: 18, color: AppColors.navy),
              ),
            )
          : Image.asset(path!, fit: BoxFit.contain),
    );
  }
}
