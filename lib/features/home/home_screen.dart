import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/sensors/step_service.dart';
import '../../domain/engines/workout_stats.dart';
import '../../domain/models/activity.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/farm_status_card.dart';
import '../../widgets/today_summary_card.dart';
import '../land/land_preview_screen.dart';
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
  var _buildingCount = 0;
  var _wateredToday = false;
  var _progressLine = '물 0회 · 울타리까지 3회';

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
    final water = await repo.loadWaterLedger();
    steps.setRecordedToday(today.steps);
    if (!mounted) return;
    setState(() {
      _today = today;
      _buildingCount = buildings.length;
      _wateredToday = water.wateredToday;
      _progressLine = water.progressLine;
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

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();
    final steps = context.watch<StepService>();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              Text(
                BalmiCopy.trustAlways,
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              ),
              const SizedBox(height: 14),
              StepLine(label: steps.label, steps: steps.displaySteps),
              const SizedBox(height: 12),
              TodaySummaryCard(
                stats: _today,
                stepLabel: steps.label,
                steps: _today.isEmpty
                    ? steps.displaySteps
                    : (_today.steps > 0 ? _today.steps : steps.displaySteps),
              ),
              const SizedBox(height: 8),
              FarmStatusCard(
                buildingCount: _buildingCount,
                progressLine: _progressLine,
                caredToday: _wateredToday,
                onOpen: () => openLandPreview(context),
              ),
              if (rec.lastError != null) ...[
                const SizedBox(height: 10),
                Text(
                  rec.lastError!,
                  style: BalmiTheme.body(size: 13, color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 18),
              Text(BalmiCopy.activityLabel, style: BalmiTheme.body(size: 15, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              ActivityPills(
                value: _activity,
                onChanged: rec.isStarting ? (_) {} : (v) => setState(() => _activity = v),
              ),
              if (_activity.isTrack) ...[
                const SizedBox(height: 8),
                TrackSpecPills(
                  value: _specM,
                  onChanged: rec.isStarting ? null : (v) => setState(() => _specM = v),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: FilledButton(
            onPressed: rec.isStarting ? null : () => _start(rec),
            child: Text(rec.isStarting ? BalmiCopy.starting : BalmiCopy.start),
          ),
        ),
      ],
    );
  }
}
