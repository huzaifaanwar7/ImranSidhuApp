import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../models/match.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'team_badge.dart';

/// Match card — matches `.match-card` from the App Design v2.0 prototype.
class MatchCard extends StatelessWidget {
  final CricketMatch match;
  const MatchCard({super.key, required this.match});

  String _statusLabel() {
    if (match.isLive) return 'LIVE';
    if (match.isCompleted) return 'COMPLETED';
    return 'UPCOMING';
  }

  Color _statusColor() {
    if (match.isLive) return AppColors.ballRed;
    if (match.isCompleted) return AppColors.navy;
    return AppColors.goldDeep;
  }

  String _topMeta() {
    final dateLabel = DateFormat('MMM d').format(match.scheduledStart);
    return '${match.stageLabel ?? 'League Match'} · $dateLabel';
  }

  String? _scoreFor(String teamId) {
    final inn = match.innings.where((i) => i.battingTeamId == teamId).toList();
    if (inn.isEmpty) return null;
    final i = inn.first;
    return '${i.totalRuns}/${i.wickets}';
  }

  String? _oversFor(String teamId) {
    final inn = match.innings.where((i) => i.battingTeamId == teamId).toList();
    if (inn.isEmpty) return null;
    return inn.first.oversDisplay;
  }

  @override
  Widget build(BuildContext context) {
    final home = MockData.teamById(match.homeTeamId);
    final away = MockData.teamById(match.awayTeamId);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/match/${match.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _topMeta().toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(
                      size: 8,
                      color: AppColors.grey,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Text(_statusLabel(),
                    style: AppTextStyles.mono(
                      size: 8,
                      color: _statusColor(),
                      weight: FontWeight.w700,
                      letterSpacing: 0.2,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            _teamRow(home, _scoreFor(home.id), _oversFor(home.id)),
            const SizedBox(height: 6),
            _teamRow(away, _scoreFor(away.id), _oversFor(away.id)),
            if (match.resultMargin != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: AppColors.line, style: BorderStyle.solid)),
                ),
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${MockData.teamById(match.resultWinnerTeamId ?? match.homeTeamId).name} ${match.resultMargin}',
                  style: AppTextStyles.italicAccent(
                      size: 11, color: AppColors.ballRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _teamRow(team, String? score, String? overs) {
    return Row(
      children: [
        TeamBadge(team: team, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.dm(size: 12, weight: FontWeight.w600)),
        ),
        if (score != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score,
                  style: AppTextStyles.fraunces(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.navyDeep)),
              if (overs != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(overs,
                      style:
                          AppTextStyles.mono(size: 9, color: AppColors.grey)),
                ),
              ],
            ],
          )
        else
          Text('—', style: AppTextStyles.mono(size: 11, color: AppColors.grey)),
      ],
    );
  }
}
