import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../domain/engines/workout_stats.dart';

/// Home card for balmi-recorded workouts vs daily exercise goals.
class TodayExerciseCard extends StatelessWidget {
  const TodayExerciseCard({
    super.key,
    required this.stats,
    required this.exerciseMinutes,
    required this.exerciseKm,
    this.compact = false,
  });

  final PeriodStats stats;
  final int exerciseMinutes;
  final double exerciseKm;

  /// Tighter padding / type for half-width home row.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = exerciseGoalProgress(
      stats: stats,
      exerciseMinutes: exerciseMinutes,
      exerciseKm: exerciseKm,
    );
    final pad = compact ? 14.0 : 18.0;
    return Semantics(
      label: stats.isEmpty
          ? '${BalmiCopy.todayExercise}. ${BalmiCopy.todayEmpty}'
          : '${BalmiCopy.todayExercise} ${_minutesLine(progress)} ${_kmLine(progress)}',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
        decoration: BalmiTheme.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BalmiCopy.todayExercise,
              style: BalmiTheme.body(
                size: compact ? 12 : 15,
                weight: FontWeight.w800,
                color: BalmiColors.sub,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            if (stats.isEmpty)
              Text(
                BalmiCopy.todayEmpty,
                style: BalmiTheme.body(
                  size: compact ? 12 : 13,
                  color: BalmiColors.sub,
                ),
              )
            else ...[
              if (stats.sessions > 1)
                Padding(
                  padding: EdgeInsets.only(bottom: compact ? 6 : 8),
                  child: Text(
                    '${stats.sessions}회',
                    style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                  ),
                ),
              _GoalTrack(
                icon: Icons.timer_outlined,
                line: _minutesLine(progress),
                ratio: progress.minutesRatio,
                compact: compact,
              ),
              SizedBox(height: compact ? 8 : 10),
              _GoalTrack(
                icon: Icons.route_outlined,
                line: _kmLine(progress),
                ratio: progress.kmRatio,
                compact: compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _minutesLine(ExerciseGoalProgress p) =>
      '${p.minutesCurrent.round()}분 / ${p.minutesTarget}분';

  static String _kmLine(ExerciseGoalProgress p) =>
      '${formatGoalKm(p.kmCurrent)} / ${formatGoalKm(p.kmTarget)} km';
}

class _GoalTrack extends StatelessWidget {
  const _GoalTrack({
    required this.icon,
    required this.line,
    required this.ratio,
    this.compact = false,
  });

  final IconData icon;
  final String line;
  final double ratio;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: compact ? 14 : 16, color: BalmiColors.potato),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                line,
                style: BalmiTheme.num(size: compact ? 13 : 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 5 : 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: compact ? 4 : 5,
            color: BalmiColors.potato,
            backgroundColor: BalmiColors.line,
          ),
        ),
      ],
    );
  }
}

String formatGoalKm(double km) {
  if (km >= 10) return km.toStringAsFixed(1);
  return km.toStringAsFixed(2);
}
