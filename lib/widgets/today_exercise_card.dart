import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../domain/engines/workout_stats.dart';
import '../domain/models/health_goals.dart';

/// Home card for balmi-recorded workouts vs daily exercise goals.
class TodayExerciseCard extends StatelessWidget {
  const TodayExerciseCard({
    super.key,
    required this.stats,
    required this.goals,
  });

  final PeriodStats stats;
  final HealthGoals goals;

  @override
  Widget build(BuildContext context) {
    final progress = exerciseGoalProgress(stats: stats, goals: goals);
    return Semantics(
      label: stats.isEmpty
          ? '${BalmiCopy.todayExercise}. ${BalmiCopy.todayEmpty}'
          : '${BalmiCopy.todayExercise} ${_minutesLine(progress)} ${_kmLine(progress)}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BalmiTheme.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BalmiCopy.todayExercise,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (stats.isEmpty)
              Text(
                BalmiCopy.todayEmpty,
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              )
            else ...[
              if (stats.sessions > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${stats.sessions}회',
                    style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                  ),
                ),
              _GoalTrack(
                icon: Icons.timer_outlined,
                line: _minutesLine(progress),
                ratio: progress.minutesRatio,
              ),
              const SizedBox(height: 10),
              _GoalTrack(
                icon: Icons.route_outlined,
                line: _kmLine(progress),
                ratio: progress.kmRatio,
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
  });

  final IconData icon;
  final String line;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: BalmiColors.potato),
            const SizedBox(width: 6),
            Expanded(
              child: Text(line, style: BalmiTheme.num(size: 16)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
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
