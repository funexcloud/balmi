import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'core/copy.dart';
import 'core/theme.dart';
import 'data/db/app_database.dart';
import 'data/repositories/session_repository.dart';
import 'data/sync/sync_worker.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/recording/recording_controller.dart';
import 'features/recovery/recovery_dialog.dart';

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
  late final SyncWorker _sync;
  bool? _onboarded;
  bool _recoveryChecked = false;

  @override
  void initState() {
    super.initState();
    _repo = SessionRepository(widget.db);
    _recording = RecordingController(repo: _repo, dbPath: widget.dbPath);
    _recording.attachTaskListener();
    _sync = SyncWorker(_repo)..start();
    _load();
  }

  Future<void> _load() async {
    await _recording.initForeground();
    final done = await isOnboardingDone(_repo);
    if (!mounted) return;
    setState(() => _onboarded = done);
  }

  @override
  void dispose() {
    _sync.stop();
    _recording.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.db),
        Provider<SessionRepository>.value(value: _repo),
        ChangeNotifierProvider<RecordingController>.value(value: _recording),
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
    final open = await repo.findRecording();
    if (!mounted) return;
    if (open != null) {
      final resume = await showRecoveryDialog(context, open);
      if (resume == true) {
        await rec.resume(open.id);
        if (mounted) {
          widget.onReady();
          return;
        }
      } else {
        await rec.endRecovered(open.id);
      }
    }
    if (mounted) widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
