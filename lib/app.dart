import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'core/copy.dart';
import 'core/theme.dart';
import 'data/db/app_database.dart';
import 'data/notifications/activity_recovery_alarms.dart';
import 'data/notifications/meal_walk_alarms.dart';
import 'data/repositories/activity_recovery_store.dart';
import 'data/repositories/meal_walk_store.dart';
import 'data/repositories/step_goal_store.dart';
import 'data/repositories/session_repository.dart';
import 'data/sensors/step_service.dart';
import 'data/sync/sync_worker.dart';
import 'domain/engines/recovery.dart';
import 'features/activity_recovery/activity_recovery_controller.dart';
import 'features/activity_recovery/activity_recovery_flow.dart';
import 'features/meal_walk/meal_walk_controller.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/step_goal_controller.dart';
import 'features/recording/recording_controller.dart';
import 'features/recovery/recovery_dialog.dart';
import 'features/session_detail/session_detail_screen.dart';
import 'features/shell/app_shell.dart';

class BalmiApp extends StatefulWidget {
  const BalmiApp({
    super.key,
    required this.db,
    required this.dbPath,
  });

  final AppDatabase db;
  final String dbPath;

  @override
  State<BalmiApp> createState() => _BalmiAppState();
}

class _BalmiAppState extends State<BalmiApp> {
  late final SessionRepository _repo;
  late final RecordingController _recording;
  late final MealWalkController _mealWalk;
  late final ActivityRecoveryController _activityRecovery;
  late final StepGoalController _stepGoal;
  late final StepService _steps;
  late final SyncWorker _sync;
  bool? _onboarded;
  bool _recoveryChecked = false;

  @override
  void initState() {
    super.initState();
    _repo = SessionRepository(widget.db);
    _recording = RecordingController(repo: _repo, dbPath: widget.dbPath);
    _recording.attachTaskListener();
    _mealWalk = MealWalkController(
      store: MealWalkStore(widget.db, newId: _repo.newId),
      repo: _repo,
      recording: _recording,
      alarms: MealWalkAlarms(),
    );
    _activityRecovery = ActivityRecoveryController(
      store: ActivityRecoveryStore(widget.db, newId: _repo.newId),
      alarms: ActivityRecoveryAlarms(),
    );
    _stepGoal = StepGoalController(store: StepGoalStore(widget.db));
    _steps = StepService(repo: _repo)..start();
    _sync = SyncWorker(_repo)..start();
    _load();
  }

  Future<void> _load() async {
    await _recording.initForeground();
    await Future.wait([
      _mealWalk.bootstrap(),
      _activityRecovery.bootstrap(),
      _stepGoal.bootstrap(),
    ]);
    final done = await isOnboardingDone(_repo);
    if (!mounted) return;
    setState(() => _onboarded = done);
  }

  @override
  void dispose() {
    _sync.stop();
    _mealWalk.dispose();
    _activityRecovery.dispose();
    _stepGoal.dispose();
    _recording.dispose();
    _steps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.db),
        Provider<SessionRepository>.value(value: _repo),
        ChangeNotifierProvider<RecordingController>.value(value: _recording),
        ChangeNotifierProvider<MealWalkController>.value(value: _mealWalk),
        ChangeNotifierProvider<ActivityRecoveryController>.value(
          value: _activityRecovery,
        ),
        ChangeNotifierProvider<StepGoalController>.value(value: _stepGoal),
        ChangeNotifierProvider<StepService>.value(value: _steps),
      ],
      child: WithForegroundTask(
        child: MaterialApp(
          title: BalmiCopy.appName,
          debugShowCheckedModeBanner: false,
          theme: BalmiTheme.light(),
          home: _home(),
        ),
      ),
    );
  }

  Widget _home() {
    if (_onboarded == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_onboarded == false) {
      return OnboardingScreen(
        onDone: () async {
          await markOnboardingDone(_repo);
          if (mounted) setState(() => _onboarded = true);
        },
      );
    }
    return _RecoveryGate(
      ready: _recoveryChecked,
      onReady: () => setState(() => _recoveryChecked = true),
    );
  }
}

class _RecoveryGate extends StatefulWidget {
  const _RecoveryGate({required this.ready, required this.onReady});

  final bool ready;
  final VoidCallback onReady;

  @override
  State<_RecoveryGate> createState() => _RecoveryGateState();
}

class _RecoveryGateState extends State<_RecoveryGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (widget.ready) return;
    final repo = context.read<SessionRepository>();
    final rec = context.read<RecordingController>();
    final open = await repo.loadRecoverableRecording();
    if (!mounted) return;
    if (open != null && SessionRecovery.needsRecovery(open)) {
      final resume = await showRecoveryDialog(context, open);
      if (resume == true) {
        final ok = await rec.resume(open.id);
        if (mounted) {
          if (!ok && rec.lastError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(rec.lastError!)),
            );
          } else if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(BalmiCopy.recoveryDone)),
            );
          }
          widget.onReady();
          return;
        }
      } else {
        await rec.endRecovered(open.id);
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          widget.onReady();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(
                sessionId: open.id,
                autoOpenRecovery: true,
              ),
            ),
          );
          return;
        }
      }
    }
    if (mounted) {
      widget.onReady();
      await _maybeOpenActivityRecheck();
    }
  }

  Future<void> _maybeOpenActivityRecheck() async {
    final recovery = context.read<ActivityRecoveryController>();
    await recovery.refreshPending();
    final pending = recovery.pendingPrompt;
    final focusId = recovery.focusCheckId;
    final id = focusId ?? pending?.id;
    if (id == null || !mounted) return;
    final record = await recovery.store.byId(id);
    if (record == null || !mounted) return;
    await openActivityRecoveryFlow(
      context,
      workoutSessionId: record.workoutSessionId,
      activity: record.activity,
      distanceM: record.distanceM,
      duration: Duration(seconds: record.durationSec),
      avgSpeedKmh: record.avgSpeedKmh,
      resumeCheckId: record.id,
    );
    recovery.clearFocus();
    await recovery.refreshPending();
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell();
  }
}
