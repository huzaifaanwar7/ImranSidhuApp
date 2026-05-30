import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Bebas Neue all-caps red CTA — matches `.cta-btn` style.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final Color color;
  final String? trailingArrow;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.color = AppColors.ballRed,
    this.trailingArrow,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: onPressed == null ? color.withValues(alpha: 0.4) : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            height: 22,
            child: loading
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        '${label.toUpperCase()}${trailingArrow != null ? '  $trailingArrow' : ''}',
                        style: AppTextStyles.bebas(
                          size: 16,
                          color: Colors.white,
                          letterSpacing: 0.12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
