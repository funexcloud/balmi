import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/sensors/step_service.dart';
import '../../domain/engines/farm_life.dart';
import '../../domain/engines/land_city.dart';
import '../../domain/engines/workout_stats.dart';
import '../../domain/models/activity.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/circle_action.dart';
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

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();
    final steps = context.watch<StepService>();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            children: [
              TodayHero(
                steps: steps.displaySteps,
                stepLabel: steps.label,
                stats: _today,
              ),
              const SizedBox(height: 20),
              FarmStatusCard(
                buildings: _buildings,
                herds: _herds,
                caredToday: _wateredToday,
                onOpen: () => openLandPreview(context),
              ),
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            children: [
              ActivityPills(
                value: _activity,
                onChanged: (v) => setState(() => _activity = v),
              ),
              if (_activity.isTrack) ...[
                const SizedBox(height: 8),
                TrackSpecPills(
                  value: _specM,
                  onChanged: (v) => setState(() => _specM = v),
                ),
              ],
              const SizedBox(height: 10),
              CircleAction(
                icon: rec.isStarting ? Icons.hourglass_empty : Icons.play_arrow,
                label: rec.isStarting ? BalmiCopy.starting : BalmiCopy.start,
                filled: true,
                size: CircleAction.playSize,
                onTap: rec.isStarting ? () {} : () => _start(rec),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
