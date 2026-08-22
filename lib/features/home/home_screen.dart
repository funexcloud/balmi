import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/sensors/step_service.dart';
import '../../data/stubs/future_features.dart';
import '../../domain/engines/workout_stats.dart';
import '../../domain/models/activity.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/today_summary_card.dart';
import '../../widgets/trust_header.dart';
import '../recording/recording_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _trackMode = false;
  int? _specM = 400;
  ActivityKind _activity = ActivityKind.auto;
  PeriodStats _today = summarizePeriod(const []);

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
    steps.setRecordedToday(today.steps);
    if (!mounted) return;
    setState(() => _today = today);
  }

  Future<void> _start(RecordingController rec) async {
    final ok = await rec.start(
      trackMode: _trackMode,
      trackSpecM: _specM,
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            children: [
              Text(BalmiCopy.oneLiner, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(BalmiCopy.positioning, style: BalmiTheme.body(size: 14, color: BalmiColors.sub)),
              const SizedBox(height: 12),
              StepLine(label: steps.label, steps: steps.displaySteps),
              const SizedBox(height: 10),
              TodaySummaryCard(
                stats: _today,
                stepLabel: steps.label,
                steps: _today.isEmpty ? steps.displaySteps : (_today.steps > 0 ? _today.steps : steps.displaySteps),
              ),
              const SizedBox(height: 16),
              TrustHeader(snapshot: rec.snapshot, waiting: false),
              if (rec.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  rec.lastError!,
                  style: BalmiTheme.body(size: 13, color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              Text(BalmiCopy.activityLabel, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              ActivityPills(
                value: _activity,
                onChanged: rec.isStarting ? (_) {} : (v) => setState(() => _activity = v),
              ),
              const SizedBox(height: 8),
              Text(
                _activity.isAuto ? BalmiCopy.sportHint : BalmiCopy.sportHintManual,
                style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: BalmiColors.paper,
                activeTrackColor: BalmiColors.plum,
                title: Text(BalmiCopy.trackMode, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
                subtitle: Text(
                  '학교·공원 트랙에서 바퀴를 셉니다',
                  style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                ),
                value: _trackMode,
                onChanged: rec.isStarting ? null : (v) => setState(() => _trackMode = v),
              ),
              if (_trackMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int?>(
                    initialValue: _specM,
                    decoration: InputDecoration(
                      labelText: BalmiCopy.trackSpec,
                      labelStyle: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: BalmiColors.line),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 400, child: Text('400m')),
                      DropdownMenuItem(value: 300, child: Text('300m')),
                      DropdownMenuItem(value: 200, child: Text('200m')),
                      DropdownMenuItem(value: null, child: Text(BalmiCopy.specFree)),
                    ],
                    onChanged: rec.isStarting ? null : (v) => setState(() => _specM = v),
                  ),
                ),
              if (!FutureFeatures.territoryEnabled && !FutureFeatures.crewEnabled)
                Text(
                  'Release 1 · F1–F4',
                  style: BalmiTheme.tracked(size: 11, trackingEm: 0.08, color: BalmiColors.sub),
                ),
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
