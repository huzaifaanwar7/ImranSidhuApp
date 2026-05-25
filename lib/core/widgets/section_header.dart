import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? italicAccent;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.italicAccent,
    this.action,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.navyDeep),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: title, style: AppTextStyles.headlineMedium),
                  if (italicAccent != null)
                    TextSpan(
                      text: ' $italicAccent',
                      style: AppTextStyles.italicAccent(size: 18),
                    ),
                ],
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${action!.toUpperCase()} →',
                  style: AppTextStyles.mono(
                    size: 9,
                    color: AppColors.goldDeep,
                    letterSpacing: 0.18,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionNumHeader extends StatelessWidget {
  final String num; // e.g. "01 — ENTRY"
  final String title; // e.g. "Welcome"
  final String? italic; // e.g. "& Discover"

  const SectionNumHeader({
    super.key,
    required this.num,
    required this.title,
    this.italic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num.toUpperCase(), style: AppTextStyles.sectionNum),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: title, style: AppTextStyles.displayMedium),
                if (italic != null)
                  TextSpan(
                    text: ' $italic',
                    style: AppTextStyles.italicAccent(size: 26),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
