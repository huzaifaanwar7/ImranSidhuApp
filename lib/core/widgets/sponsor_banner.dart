import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/sponsor.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SponsorBanner extends StatelessWidget {
  final SponsorSlot slot;
  final String? labelOverride;
  final bool dense;
  final EdgeInsetsGeometry padding;

  const SponsorBanner({
    super.key,
    required this.slot,
    this.labelOverride,
    this.dense = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
  });

  String _labelFor(SponsorSlot s) {
    switch (s) {
      case SponsorSlot.splash:
        return 'IN\nASSOCIATION';
      case SponsorSlot.dashboard:
        return 'OUR\nPARTNERS';
      case SponsorSlot.scorecard:
        return 'SPONSORED\nSCORECARD';
      case SponsorSlot.commentary:
        return 'OVER\nSPONSOR';
      case SponsorSlot.overCard:
        return 'PRESENTED\nBY';
      case SponsorSlot.kit:
        return 'KIT\nSPONSOR';
      case SponsorSlot.matchPresentedBy:
        return 'TITLE\nSPONSORS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sponsors = MockData.sponsors
        .where((s) => s.isActive && s.slots.contains(slot))
        .toList();
    final label = labelOverride ?? _labelFor(slot);
    if (sponsors.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
          : padding,
      decoration: const BoxDecoration(
        gradient: AppColors.creamGradient,
        border: Border(
          top: BorderSide(color: AppColors.line),
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: dense ? 62 : 70,
            child: Text(
              label,
              style: AppTextStyles.mono(
                size: dense ? 7 : 8,
                color: AppColors.grey,
                letterSpacing: 0.25,
                weight: FontWeight.w600,
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: dense ? 8 : 12,
                runSpacing: 6,
                children: sponsors
                    .map((s) => _SponsorLogo(sponsor: s, dense: dense))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorLogo extends StatelessWidget {
  final Sponsor sponsor;
  final bool dense;

  const _SponsorLogo({required this.sponsor, required this.dense});

  @override
  Widget build(BuildContext context) {
    final isAmas = sponsor.id == 'amas';
    final logoWidth = dense ? (isAmas ? 52.0 : 34.0) : (isAmas ? 70.0 : 44.0);
    final logoHeight = dense ? 28.0 : 36.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoWidth,
          height: logoHeight,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.line),
          ),
          child: _SponsorLogoImage(sponsor: sponsor),
        ),
        if (!dense) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: isAmas ? 88 : 112,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sponsor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.fraunces(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (sponsor.tagline != null)
                  Text(
                    sponsor.tagline!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(size: 7, letterSpacing: 0.18),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SponsorLogoImage extends StatelessWidget {
  final Sponsor sponsor;

  const _SponsorLogoImage({required this.sponsor});

  @override
  Widget build(BuildContext context) {
    final logoUrl = sponsor.logoUrl;
    if (logoUrl == null) return _SponsorFallback(name: sponsor.name);

    return Image.asset(
      logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _SponsorFallback(name: sponsor.name),
    );
  }
}

class _SponsorFallback extends StatelessWidget {
  final String name;

  const _SponsorFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final brand = switch (name) {
      'Amas' => AppColors.amasGreen,
      'PM Sports Hosiery' => AppColors.pmBlue,
      _ => AppColors.gold,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          name.substring(0, 1),
          style: AppTextStyles.bebas(size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
