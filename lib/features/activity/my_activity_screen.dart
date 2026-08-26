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
import '../../widgets/session_row.dart';
import '../../widgets/today_exercise_card.dart';
import '../session_detail/session_detail_screen.dart';
import '../settings/step_goal_controller.dart';

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
    final stepGoal = context.watch<StepGoalController>();
    final filtered = _all.where((r) => r.matchesFilter(_filter)).toList();
    // Full-day exercise summary (home parity); filter applies to period + log below.
    final todayExercise = summarizePeriod(inLocalDay(_all, now));
    final today = summarizePeriod(inLocalDay(filtered, now));
    final week = summarizePeriod(inLocalWeek(filtered, now));
    final month = summarizePeriod(inLocalMonth(filtered, now));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 20, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: BalmiColors.ink),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TodayExerciseCard(
                stats: todayExercise,
                exerciseMinutes: stepGoal.exerciseMinutes,
                exerciseKm: stepGoal.exerciseKm,
              ),
              const SizedBox(height: 14),
              ActivityPills(
                value: _filter ?? ActivityKind.auto,
                onChanged: (v) => setState(() => _filter = v == ActivityKind.auto ? null : v),
              ),
              const SizedBox(height: 16),
              _periodCard([
                ('오늘', today),
                ('이번 주', week),
                ('이번 달', month),
              ]),
              const SizedBox(height: 16),
              for (final r in filtered)
                SessionRow(
                  startedAt: r.startedAt,
                  activityLabel: r.activity.label,
                  distM: r.totalDistM,
                  trailing: formatElapsed(r.duration),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: r.id)),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _periodCard(List<(String, PeriodStats)> rows) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BalmiTheme.card(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: BalmiColors.line),
            _periodLine(rows[i].$1, rows[i].$2),
          ],
        ],
      ),
    );
  }

  Widget _periodLine(String title, PeriodStats s) {
    final breakdown = ActivityKind.selectable
        .where((a) => !a.isAuto && (s.byActivity[a] ?? 0) > 0)
        .map((a) => '${a.label} ${formatKm(s.byActivity[a] ?? 0)}km')
        .join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(title, style: BalmiTheme.body(size: 14, weight: FontWeight.w800)),
        ),
        Expanded(
          child: Text(
            s.isEmpty
                ? BalmiCopy.todayEmpty
                : '${s.sessions}회 · ${formatKm(s.distM)}km · ${formatElapsed(s.duration)}'
                    '${breakdown.isEmpty ? '' : '\n$breakdown'}',
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
          ),
        ),
      ],
    );
  }
}
