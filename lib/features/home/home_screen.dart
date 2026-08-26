import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/sensors/step_service.dart';
import '../../domain/engines/farm_life.dart';
import '../../domain/engines/land_city.dart';
import '../../domain/engines/meal_walk.dart';
import '../../domain/engines/workout_stats.dart';
import '../../domain/models/activity.dart';
import '../../widgets/activity_circle_picker.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/circle_action.dart';
import '../../widgets/farm_status_card.dart';
import '../../widgets/today_exercise_card.dart';
import '../../widgets/today_summary_card.dart';
import '../land/land_preview_screen.dart';
import '../meal_walk/meal_walk_cards.dart';
import '../meal_walk/meal_walk_controller.dart';
import '../meal_walk/meal_walk_onboarding.dart';
import '../settings/step_goal_controller.dart';
import '../recording/recording_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _specM = 400;
  ActivityKind _activity = ActivityKind.auto;
  PeriodStats _today = summarizePeriod(const []);
  List<FarmKind> _buildings = const [];
  List<HerdKind> _herds = const [];
  var _wateredToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final repo = context.read<SessionRepository>();
    final steps = context.read<StepService>();
    final rows = await repo.closedWorkouts();
    final today = summarizePeriod(inLocalDay(rows, DateTime.now()));
    final buildings = await repo.listBuildings();
    final livestock = await repo.listLivestock();
    final water = await repo.loadWaterLedger();
    steps.setRecordedToday(today.steps);
    if (!mounted) return;
    setState(() {
      _today = today;
      _buildings = buildings.map((b) => FarmKind.fromWire(b.type)).toList();
      _herds = livestock.map((h) => HerdKind.fromWire(h.kind)).toList();
      _wateredToday = water.wateredToday;
    });
  }

  Future<void> _start(RecordingController rec) async {
    final ok = await rec.start(
      trackSpecM: _activity.isTrack ? _specM : null,
      activity: _activity,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rec.lastError ?? BalmiCopy.startFailed)),
      );
    }
  }

  Future<void> _pickTrackSpec() async {
    await showBalmiSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: TrackSpecPills(
            value: _specM,
            onChanged: (v) {
              setState(() => _specM = v);
              Navigator.of(ctx).pop();
            },
          ),
        );
      },
    );
  }

  Future<void> _onLongPressPlay(BuildContext btnCtx) async {
    final box = btnCtx.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(box.size.center(Offset.zero));
    final picked = await showActivityCirclePicker(
      context: context,
      selected: _activity,
      origin: origin,
    );
    if (picked == null || !mounted) return;
    setState(() => _activity = picked);
    if (picked.isTrack) await _pickTrackSpec();
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();
    final steps = context.watch<StepService>();
    final stepGoal = context.watch<StepGoalController>();
    final meal = context.watch<MealWalkController>();
    final due = meal.mealDueNow();
    final showDiscover = !meal.enabled && !meal.discoverHidden;
    final showStart = meal.enabled &&
        due != null &&
        !meal.mealsToday.contains(due) &&
        meal.open == null;
    final showGo = meal.enabled && meal.open?.status == MealWalkStatus.prompted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (meal.lastFeedback != null) snackMealWalk(context, meal);
    });
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TodayStepsCard(
                        steps: steps.displaySteps,
                        stepLabel: steps.label,
                        stepGoal: stepGoal.goal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TodayExerciseCard(
                        stats: _today,
                        exerciseMinutes: stepGoal.exerciseMinutes,
                        exerciseKm: stepGoal.exerciseKm,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FarmStatusCard(
                buildings: _buildings,
                herds: _herds,
                caredToday: _wateredToday,
                onOpen: () => openLandPreview(context),
              ),
              if (showDiscover) ...[
                const SizedBox(height: 12),
                MealWalkDiscoverCard(
                  onStart: () => openMealWalkOnboarding(context, meal),
                  onDismiss: meal.hideDiscover,
                ),
              ],
              if (showStart) ...[
                const SizedBox(height: 12),
                MealWalkStartCard(
                  meal: due,
                  onStart: () => meal.confirmMealStart(due),
                ),
              ],
              if (showGo) ...[
                const SizedBox(height: 12),
                MealWalkGoCard(
                  onGo: () => meal.beginWalk(meal.open!.id),
                ),
              ],
              if (rec.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  rec.lastError!,
                  style: BalmiTheme.body(size: 13, color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Builder(
            builder: (btnCtx) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CircleAction(
                    icon: rec.isStarting ? Icons.hourglass_empty : Icons.play_arrow,
                    label: rec.isStarting ? BalmiCopy.starting : BalmiCopy.start,
                    filled: true,
                    size: CircleAction.playSize,
                    onTap: rec.isStarting ? () {} : () => _start(rec),
                    onLongPress:
                        rec.isStarting ? null : () => _onLongPressPlay(btnCtx),
                  ),
                  if (!rec.isStarting && !_activity.isAuto)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Semantics(
                        label: _activity.label,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: BalmiColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: BalmiColors.potato, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: ActivityPills.glyphOf(
                              _activity,
                              size: 16,
                              color: BalmiColors.potato,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
