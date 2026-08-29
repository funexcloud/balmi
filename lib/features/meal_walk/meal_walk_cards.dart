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

class MealWalkPersistentCard extends StatelessWidget {
  const MealWalkPersistentCard({
    super.key,
    required this.session,
    required this.onStartMeal,
    required this.onStartWalk,
    required this.onResumeWalk,
    required this.onOpenHub,
  });

  final MealWalkSession? session;
  final VoidCallback onStartMeal;
  final VoidCallback onStartWalk;
  final VoidCallback onResumeWalk;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = session != null
        ? evaluateSessionStatus(session!, now)
        : MealWalkStatus.notStarted;

    final accumulatedMin = session != null ? (session!.walkDurationSec ~/ 60) : 0;
    final remainingMin = session != null ? ((session!.remainingTargetSeconds + 59) ~/ 60) : 15;

    Widget buildBody() {
      switch (status) {
        case MealWalkStatus.notStarted:
        case MealWalkStatus.expired:
          return Row(
            children: [
              const Icon(Icons.restaurant, color: BalmiColors.potato, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BalmiCopy.mealWalkHubTitle,
                      style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '식후 15분 걷기 습관',
                      style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BalmiColors.potato,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onStartMeal,
                child: Text(
                  BalmiCopy.mealWalkStartBtn,
                  style: BalmiTheme.body(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          );

        case MealWalkStatus.mealCountdown:
          final left = remainingCountdown(session!, now);
          return Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: BalmiColors.potato, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '식후 걷기까지',
                      style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '30분 대기 후 15분 산책',
                      style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatElapsed(left),
                style: BalmiTheme.num(size: 20, color: BalmiColors.potatoDk),
              ),
            ],
          );

        case MealWalkStatus.readyToWalk:
          return Row(
            children: [
              const Icon(Icons.directions_walk, color: BalmiColors.potato, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘 식후 걷기가 남아 있어요',
                      style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '0 / 15분',
                      style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BalmiColors.potato,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onStartWalk,
                child: Text(
                  '지금 걷기',
                  style: BalmiTheme.body(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          );

        case MealWalkStatus.paused:
          return Row(
            children: [
              const Icon(Icons.pause_circle_outline, color: BalmiColors.potato, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘 ${accumulatedMin}분 걸었어요',
                      style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${remainingMin}분 남았습니다',
                      style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BalmiColors.potato,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onResumeWalk,
                child: Text(
                  '이어 걷기',
                  style: BalmiTheme.body(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          );

        case MealWalkStatus.completed:
          return Row(
            children: [
              const Icon(Icons.check_circle_outline, color: BalmiColors.sage, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘 식후 걷기 완료',
                      style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '15분 ✓',
                      style: BalmiTheme.body(size: 12, color: BalmiColors.sage, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BalmiColors.sub),
            ],
          );

        case MealWalkStatus.walking:
          return Row(
            children: [
              const Icon(Icons.directions_walk, color: BalmiColors.potato, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '식후 걷기 진행 중',
                      style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '누적 ${accumulatedMin}분 걸음',
                      style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BalmiColors.potato),
            ],
          );
      }
    }

    return Material(
      color: BalmiColors.mist,
      borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
        onTap: onOpenHub,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: buildBody(),
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              const Icon(Icons.restaurant, color: BalmiColors.potato, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BalmiCopy.mealWalkStartPrompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: BalmiCopy.mealWalkStartBtn,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BalmiColors.potato,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onStart,
                  child: Text(
                    BalmiCopy.mealWalkStartBtn,
                    style: BalmiTheme.body(size: 13, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MealWalkPendingCard extends StatelessWidget {
  const MealWalkPendingCard({
    super.key,
    required this.mealStartedAt,
  });

  final DateTime mealStartedAt;

  @override
  Widget build(BuildContext context) {
    final promptAt = walkPromptAt(mealStartedAt);
    final remaining = promptAt.difference(DateTime.now());
    final leftSec = remaining.isNegative ? Duration.zero : remaining;

    return Material(
      color: BalmiColors.mist,
      borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: BalmiColors.potato, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BalmiCopy.mealWalkPendingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    BalmiCopy.mealWalkPendingHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatElapsed(leftSec),
              style: BalmiTheme.num(size: 20, color: BalmiColors.potatoDk),
            ),
          ],
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              const Icon(Icons.directions_walk, color: BalmiColors.potato, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  BalmiCopy.mealWalkGoShort,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.play_arrow_rounded, color: BalmiColors.potato, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class MealWalkStatusHubCard extends StatelessWidget {
  const MealWalkStatusHubCard({
    super.key,
    required this.onOpenHub,
  });

  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    return MealWalkPersistentCard(
      session: null,
      onStartMeal: onOpenHub,
      onStartWalk: onOpenHub,
      onResumeWalk: onOpenHub,
      onOpenHub: onOpenHub,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: BalmiColors.ink.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_walk, color: BalmiColors.potato, size: 20),
          const SizedBox(width: 8),
          Text(
            '식후 걷기: ${formatElapsed(remaining)} 남음',
            style: BalmiTheme.body(size: 13, color: Colors.white, weight: FontWeight.w700),
          ),
        ],
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
