import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../domain/engines/workout_stats.dart';

/// Today's numbers as the hero — step label, optional daily goal progress.
class TodayHero extends StatelessWidget {
  const TodayHero({
    super.key,
    required this.stats,
    required this.stepLabel,
    required this.steps,
    this.stepGoal,
    this.compact = false,
    this.showWorkoutExtras = true,
  });

  final PeriodStats stats;
  final String stepLabel;
  final int steps;
  final int? stepGoal;

  /// Smaller type for half-width home row.
  final bool compact;

  /// When false, only steps + goal (no km / duration line).
  final bool showWorkoutExtras;

  @override
  Widget build(BuildContext context) {
    final goal = stepGoal;
    final hasGoal = goal != null && goal > 0;
    final ratio = hasGoal ? (steps / goal).clamp(0.0, 1.0) : null;
    final numSize = compact ? 36.0 : 56.0;
    final labelSize = compact ? 12.0 : 13.0;
    return Semantics(
      label: '$stepLabel $steps'
          '${hasGoal ? ' / $goal' : ''}'
          '${!showWorkoutExtras || stats.isEmpty ? '' : ' ${formatKm(stats.distM)}km ${formatElapsed(stats.duration)}'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepLabel,
            style: BalmiTheme.body(
              size: labelSize,
              weight: FontWeight.w800,
              color: BalmiColors.sub,
            ),
          ),
          SizedBox(height: compact ? 6 : 4),
          Text('$steps', style: BalmiTheme.num(size: numSize)),
          if (hasGoal) ...[
            SizedBox(height: compact ? 8 : 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: compact ? 5 : 6,
                color: BalmiColors.potato,
                backgroundColor: BalmiColors.line,
              ),
            ),
            SizedBox(height: compact ? 6 : 6),
            Text(
              '${formatSteps(steps)} / ${formatSteps(goal)}',
              style: BalmiTheme.body(
                size: compact ? 11 : 13,
                color: BalmiColors.sub,
              ),
            ),
          ],
          if (showWorkoutExtras && !stats.isEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${formatKm(stats.distM)}km', style: BalmiTheme.num(size: 22)),
                const SizedBox(width: 18),
                Text(formatElapsed(stats.duration), style: BalmiTheme.num(size: 22)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Home half-width card: 오늘 걸음 count + goal progress.
class TodayStepsCard extends StatelessWidget {
  const TodayStepsCard({
    super.key,
    required this.stepLabel,
    required this.steps,
    this.stepGoal,
  });

  final String stepLabel;
  final int steps;
  final int? stepGoal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BalmiTheme.card(),
      child: TodayHero(
        stats: summarizeEmpty,
        stepLabel: stepLabel,
        steps: steps,
        stepGoal: stepGoal,
        compact: true,
        showWorkoutExtras: false,
      ),
    );
  }
}

class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    super.key,
    required this.stats,
    required this.stepLabel,
    required this.steps,
    this.stepGoal,
  });

  final PeriodStats stats;
  final String stepLabel;
  final int steps;
  final int? stepGoal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BalmiTheme.card(),
      child: TodayHero(
        stats: stats,
        stepLabel: stepLabel,
        steps: steps,
        stepGoal: stepGoal,
      ),
    );
  }
}

class StepLine extends StatelessWidget {
  const StepLine({
    super.key,
    required this.label,
    required this.steps,
    this.stepGoal,
  });

  final String label;
  final int steps;
  final int? stepGoal;

  @override
  Widget build(BuildContext context) {
    return TodayHero(
      stats: summarizeEmpty,
      stepLabel: label,
      steps: steps,
      stepGoal: stepGoal,
    );
  }
}

PeriodStats get summarizeEmpty => summarizePeriod(const []);
