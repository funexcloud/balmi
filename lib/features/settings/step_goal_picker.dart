import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repositories/step_goal_store.dart';
import 'step_goal_controller.dart';

class StepGoalPicker extends StatelessWidget {
  const StepGoalPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<StepGoalController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flag_outlined, color: BalmiColors.potato),
          title: Text(
            BalmiCopy.dailyStepGoal,
            style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
          ),
          subtitle: Text(
            BalmiCopy.dailyStepGoalHint,
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in kDailyStepGoalPresets)
              _GoalChip(
                label: formatSteps(preset),
                selected: goal.goal == preset,
                onTap: () => goal.setGoal(preset),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${formatSteps(goal.goal)}걸음',
              style: BalmiTheme.num(size: 18, color: BalmiColors.ink),
            ),
            Text(
              '드래그로 조절',
              style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: BalmiColors.potato,
            inactiveTrackColor: BalmiColors.mist,
            thumbColor: BalmiColors.potato,
            overlayColor: BalmiColors.potato.withValues(alpha: 0.12),
            trackHeight: 6,
          ),
          child: Slider(
            value: goal.goal.toDouble().clamp(1000.0, 30000.0),
            min: 1000.0,
            max: 30000.0,
            divisions: 58,
            label: '${formatSteps(goal.goal)}걸음',
            onChanged: (val) {
              goal.setGoal((val / 500).round() * 500);
            },
          ),
        ),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BalmiColors.potato : BalmiColors.mist,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: BalmiTheme.body(
              size: 14,
              weight: FontWeight.w800,
              color: selected ? Colors.white : BalmiColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
