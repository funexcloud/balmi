import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../domain/engines/workout_stats.dart';

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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BalmiColors.line),
      ),
      child: stats.isEmpty
          ? Text(BalmiCopy.todayEmpty, style: BalmiTheme.body(size: 14, color: BalmiColors.sub))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(BalmiCopy.todaySummary, style: BalmiTheme.tracked(color: BalmiColors.plum)),
                const SizedBox(height: 4),
                Text(
                  '${stats.sessions}회 · ${formatKm(stats.distM)}km · ${formatElapsed(stats.duration)}',
                  style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.primaryActivity?.label ?? BalmiCopy.activityAuto} · $stepLabel $steps',
                  style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                ),
              ],
            ),
    );
  }
}

class StepLine extends StatelessWidget {
  const StepLine({super.key, required this.label, required this.steps});

  final String label;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BalmiTheme.tracked(size: 11, trackingEm: 0.12)),
        Text('$steps', style: BalmiTheme.num(size: 36)),
      ],
    );
  }
}
