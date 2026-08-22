import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/sensors/step_service.dart';
import '../../domain/engines/workout_stats.dart';
import '../../domain/models/activity.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/today_summary_card.dart';
import '../session_detail/session_detail_screen.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  List<WorkoutRow> _all = [];
  ActivityKind? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await context.read<SessionRepository>().closedWorkouts();
    if (!mounted) return;
    setState(() => _all = rows);
    context.read<StepService>().setRecordedToday(
          summarizePeriod(inLocalDay(rows, DateTime.now())).steps,
        );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final steps = context.watch<StepService>();
    final filtered = _all.where((r) => r.matchesFilter(_filter)).toList();
    final today = summarizePeriod(inLocalDay(filtered, now));
    final week = summarizePeriod(inLocalWeek(filtered, now));
    final month = summarizePeriod(inLocalMonth(filtered, now));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StepLine(label: steps.label, steps: steps.displaySteps),
        const SizedBox(height: 10),
        TodaySummaryCard(
          stats: today,
          stepLabel: steps.label,
          steps: today.steps > 0 ? today.steps : steps.displaySteps,
        ),
        const SizedBox(height: 16),
        Text(BalmiCopy.activityLabel, style: BalmiTheme.body(size: 15, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        ActivityPills(
          value: _filter ?? ActivityKind.auto,
          onChanged: (v) => setState(() => _filter = v == ActivityKind.auto ? null : v),
        ),
        const SizedBox(height: 18),
        _period('오늘', today),
        _period('이번 주', week),
        _period('이번 달', month),
        const SizedBox(height: 12),
        Text(BalmiCopy.workoutLogTab, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...filtered.map((r) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${formatDateTime(r.startedAt)} · ${r.activity.label}',
              style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
            ),
            subtitle: Text(
              '${formatKm(r.totalDistM)}km · ${formatElapsed(r.duration)}',
              style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: r.id)),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _period(String title, PeriodStats s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
          Text(
            s.isEmpty
                ? BalmiCopy.todayEmpty
                : '${s.sessions}회 · ${formatKm(s.distM)}km · ${formatElapsed(s.duration)}',
            style: BalmiTheme.body(size: 14, color: BalmiColors.sub),
          ),
          if (!s.isEmpty)
            Text(
              ActivityKind.selectable
                  .where((a) => !a.isAuto && (s.byActivity[a] ?? 0) > 0)
                  .map((a) => '${a.label} ${formatKm(s.byActivity[a] ?? 0)}km')
                  .join(' · '),
              style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
            ),
        ],
      ),
    );
  }
}
