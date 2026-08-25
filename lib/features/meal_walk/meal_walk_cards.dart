import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/engines/meal_walk.dart';
import 'meal_walk_controller.dart';

class MealWalkDiscoverCard extends StatelessWidget {
  const MealWalkDiscoverCard({
    super.key,
    required this.onStart,
    required this.onDismiss,
  });

  final VoidCallback onStart;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BalmiColors.mist,
      borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, color: BalmiColors.potato, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                BalmiCopy.mealWalkDiscover,
                style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: BalmiCopy.mealWalkDismiss,
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: BalmiColors.sub),
            ),
            IconButton(
              tooltip: BalmiCopy.continueLabel,
              onPressed: onStart,
              icon: const Icon(Icons.chevron_right, color: BalmiColors.potato),
            ),
          ],
        ),
      ),
    );
  }
}

class MealWalkStartCard extends StatelessWidget {
  const MealWalkStartCard({
    super.key,
    required this.meal,
    required this.onStart,
  });

  final MealType meal;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BalmiColors.mist,
      borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              const Icon(Icons.restaurant, color: BalmiColors.potato, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BalmiCopy.mealWalkStartPrompt,
                      style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                    ),
                    Text(
                      meal.label,
                      style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: BalmiCopy.mealWalkStartBtn,
                child: const Icon(Icons.play_arrow, color: BalmiColors.potato, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MealWalkGoCard extends StatelessWidget {
  const MealWalkGoCard({super.key, required this.onGo});

  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BalmiColors.mist,
      borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
        onTap: onGo,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              const Icon(Icons.directions_walk, color: BalmiColors.potato, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  BalmiCopy.mealWalkGoShort,
                  style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.play_arrow, color: BalmiColors.potato, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class MealWalkCountdownBanner extends StatelessWidget {
  const MealWalkCountdownBanner({
    super.key,
    required this.remaining,
    required this.elapsed,
  });

  final Duration remaining;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BalmiColors.mist,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, color: BalmiColors.potato),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                BalmiCopy.mealWalkWalkGoal,
                style: BalmiTheme.body(size: 13, weight: FontWeight.w800),
              ),
            ),
            Text(
              formatElapsed(remaining),
              style: BalmiTheme.num(size: 22, color: BalmiColors.potato),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> snackMealWalk(BuildContext context, MealWalkController meal) {
  final msg = meal.lastFeedback?.message;
  if (msg == null) return Future.value();
  meal.lastFeedback = null;
  return ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)))
      .closed
      .then((_) {});
}
