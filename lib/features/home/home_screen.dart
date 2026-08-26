import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import '../activity_recovery/activity_recovery_controller.dart';
import '../activity_recovery/activity_recovery_flow.dart';
import '../land/farm_preview_screen.dart';
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
      trackSpecM:
          rec.preferredActivity.isTrack ? rec.preferredTrackSpecM : null,
      activity: rec.preferredActivity,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rec.lastError ?? BalmiCopy.startFailed)),
      );
    }
  }

  Future<void> _reportStartFailure(RecordingController rec) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(rec.lastError ?? BalmiCopy.startFailed)),
    );
  }

  /// Track meters sheet. Returns a selection when the user taps a chip;
  /// `null` means the sheet was dismissed without choosing.
  Future<_TrackSpecChoice?> _pickTrackSpec(RecordingController rec) async {
    // Let the sport-picker route finish closing so its pointer-up cannot
    // immediately dismiss this sheet (same race as long-press → picker).
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return null;

    return showBalmiSheet<_TrackSpecChoice>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: TrackSpecPills(
            value: rec.preferredTrackSpecM,
            onChanged: (v) {
              Navigator.of(ctx).pop(_TrackSpecChoice(v));
            },
          ),
        );
      },
    );
  }

  Future<void> _onLongPressPlay(BuildContext btnCtx) async {
    final box = btnCtx.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(box.size.center(Offset.zero));

    // Wait until the long-press pointer-up is done so it cannot dismiss the
    // picker barrier immediately (classic showDialog-from-onLongPress race).
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;

    final rec = context.read<RecordingController>();
    final picked = await showActivityCirclePicker(
      context: context,
      selected: rec.preferredActivity,
      origin: origin,
    );
    if (picked == null || !mounted) return;

    if (picked.isTrack) {
      // Remember 트랙 so the play badge updates; meters + start happen on chip tap.
      rec.setPreferredActivity(ActivityKind.track);
      final choice = await _pickTrackSpec(rec);
      if (!mounted) return;
      if (choice == null) return; // dismissed — preference kept, no auto-start
      if (rec.isStarting || rec.isRecording) return;
      final ok = await rec.startPreferred(
        ActivityKind.track,
        trackSpecM: choice.specM,
      );
      if (!ok) await _reportStartFailure(rec);
      return;
    }

    if (rec.isStarting || rec.isRecording) return;
    final ok = await rec.startPreferred(picked);
    if (!ok) await _reportStartFailure(rec);
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
    final preferred = rec.preferredActivity;
    final recovery = context.watch<ActivityRecoveryController>();
    final recoveryDue = recovery.pendingPrompt;
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
                onOpen: () => openFarmPreview(context),
              ),
              if (recoveryDue != null) ...[
                const SizedBox(height: 12),
                Material(
                  color: BalmiColors.mist,
                  borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
                    onTap: () async {
                      await openActivityRecoveryFlow(
                        context,
                        workoutSessionId: recoveryDue.workoutSessionId,
                        activity: recoveryDue.activity,
                        distanceM: recoveryDue.distanceM,
                        duration: Duration(seconds: recoveryDue.durationSec),
                        avgSpeedKmh: recoveryDue.avgSpeedKmh,
                        resumeCheckId: recoveryDue.id,
                      );
                      if (!context.mounted) return;
                      await recovery.refreshPending();
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_outline,
                            color: BalmiColors.potato,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              BalmiCopy.activityRecoveryPending,
                              style: BalmiTheme.body(
                                size: 15,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: BalmiColors.potato,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                  if (!rec.isStarting && !preferred.isAuto)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: IgnorePointer(
                        child: Semantics(
                          label: preferred.label,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: BalmiColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: BalmiColors.potato, width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: ActivityPills.glyphOf(
                                preferred,
                                size: 16,
                                color: BalmiColors.potato,
                              ),
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

/// Explicit track-meter chip selection ( [specM] may be null for 자유 ).
class _TrackSpecChoice {
  const _TrackSpecChoice(this.specM);
  final int? specM;
}
