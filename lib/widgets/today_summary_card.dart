import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../domain/engines/workout_stats.dart';

/// Today's numbers as the hero — no goal bars or Korean captions.
class TodayHero extends StatelessWidget {
  const TodayHero({
    super.key,
    required this.stats,
    required this.stepLabel,
    required this.steps,
  });

  final PeriodStats stats;
  final String stepLabel;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stepLabel $steps'
          '${stats.isEmpty ? '' : ' ${formatKm(stats.distM)}km ${formatElapsed(stats.duration)}'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$steps', style: BalmiTheme.num(size: 56)),
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
  });

  final PeriodStats stats;
  final String stepLabel;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BalmiTheme.card(),
      child: TodayHero(stats: stats, stepLabel: stepLabel, steps: steps),
    );
  }
}

class StepLine extends StatelessWidget {
  const StepLine({super.key, required this.label, required this.steps});

  final String label;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return TodayHero(
      stats: summarizeEmpty,
      stepLabel: label,
      steps: steps,
    );
  }
}

PeriodStats get summarizeEmpty => summarizePeriod(const []);
