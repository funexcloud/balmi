import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/repositories/step_goal_store.dart';
import 'step_goal_controller.dart';
import 'step_goal_picker.dart';

class DailyGoalsPicker extends StatelessWidget {
  const DailyGoalsPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<StepGoalController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          BalmiCopy.dailyGoals,
          style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
        ),
        const SizedBox(height: 4),
        Text(
          BalmiCopy.dailyGoalsHint,
          style: BalmiTheme.body(size: 12, color: BalmiColors.sub, height: 1.4),
        ),
        const SizedBox(height: 12),
        const StepGoalPicker(),
        const SizedBox(height: 16),
        _ExerciseMinutesPicker(
          value: goals.exerciseMinutes,
          onChanged: goals.setExerciseMinutes,
        ),
        const SizedBox(height: 16),
        _ExerciseKmPicker(
          value: goals.exerciseKm,
          onChanged: goals.setExerciseKm,
        ),
      ],
    );
  }
}

class _ExerciseMinutesPicker extends StatelessWidget {
  const _ExerciseMinutesPicker({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.timer_outlined, color: BalmiColors.potato),
          title: Text(
            BalmiCopy.exerciseTimeGoal,
            style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in kDailyExerciseMinPresets)
              _GoalChip(
                label: '$preset${BalmiCopy.goalMinutesUnit}',
                selected: value == preset,
                onTap: () => onChanged(preset),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$value${BalmiCopy.goalMinutesUnit}',
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
            value: value.toDouble().clamp(5.0, 180.0),
            min: 5.0,
            max: 180.0,
            divisions: 35,
            label: '$value${BalmiCopy.goalMinutesUnit}',
            onChanged: (val) {
              onChanged((val / 5).round() * 5);
            },
          ),
        ),
      ],
    );
  }
}

class _ExerciseKmPicker extends StatelessWidget {
  const _ExerciseKmPicker({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.route_outlined, color: BalmiColors.potato),
          title: Text(
            BalmiCopy.exerciseDistanceGoal,
            style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in kDailyExerciseKmPresets)
              _GoalChip(
                label: '${preset.toStringAsFixed(preset == preset.roundToDouble() ? 0 : 1)} ${BalmiCopy.goalKmUnit}',
                selected: (value - preset).abs() < 1e-6,
                onTap: () => onChanged(preset),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${value.toStringAsFixed(1)} ${BalmiCopy.goalKmUnit}',
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
            value: value.clamp(0.5, 30.0),
            min: 0.5,
            max: 30.0,
            divisions: 59,
            label: '${value.toStringAsFixed(1)} ${BalmiCopy.goalKmUnit}',
            onChanged: (val) {
              onChanged((val * 2).round() / 2.0);
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
