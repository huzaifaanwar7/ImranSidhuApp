import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../models/team.dart';
import '../theme/app_text_styles.dart';

/// Flat rounded-square team flag with letter code — matches App Design v2.0.
class TeamBadge extends StatelessWidget {
  final Team team;
  final double size;
  final bool showName;
  final bool stacked;

  const TeamBadge({
    super.key,
    required this.team,
    this.size = 36,
    this.showName = false,
    this.stacked = false,
  });

  List<Color> _palette() {
    return [team.primaryColor, team.secondaryColor];
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final logoUrl = ApiClient.imageUrl(team.flagUrl);
    final radius = BorderRadius.circular(size * 0.18);
    final letterChild = Text(
      team.shortCode,
      style: AppTextStyles.bebas(
        size: size * 0.38,
        color: Colors.white,
        letterSpacing: 0.04,
      ),
    );
    final flag = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: p.first.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      clipBehavior: logoUrl != null ? Clip.antiAlias : Clip.none,
      child: logoUrl == null
          ? letterChild
          : Image.network(
              logoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: letterChild),
            ),
    );

    if (!showName) return flag;

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          flag,
          const SizedBox(height: 6),
          SizedBox(
            width: size + 30,
            child: Text(
              team.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.fraunces(size: 12, weight: FontWeight.w700),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        flag,
        const SizedBox(width: 10),
        Text(team.name,
            style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w700)),
      ],
    );
  }
}
