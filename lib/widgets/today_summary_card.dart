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
  });

  final PeriodStats stats;
  final String stepLabel;
  final int steps;
  final int? stepGoal;

  @override
  Widget build(BuildContext context) {
    final goal = stepGoal;
    final hasGoal = goal != null && goal > 0;
    final ratio = hasGoal ? (steps / goal).clamp(0.0, 1.0) : null;
    return Semantics(
      label: '$stepLabel $steps'
          '${hasGoal ? ' / $goal' : ''}'
          '${stats.isEmpty ? '' : ' ${formatKm(stats.distM)}km ${formatElapsed(stats.duration)}'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepLabel,
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
          ),
          const SizedBox(height: 4),
          Text('$steps', style: BalmiTheme.num(size: 56)),
          if (hasGoal) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: BalmiColors.potato,
                backgroundColor: BalmiColors.line,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${formatSteps(steps)} / ${formatSteps(goal)}',
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
            ),
          ],
          if (!stats.isEmpty) ...[
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
