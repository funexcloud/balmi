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

enum _ActivityPeriod { day, week, month }

/// My Activity: period filter → 오늘의 운동 / period summary → session list.
/// Never reintroduce home's 오늘 걸음 / step heroes (`TodayStepsCard` / `TodayHero`).
/// Land reward stays on session detail — not forced here.
/// Regression: `test/my_activity_screen_test.dart`.
class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  List<WorkoutRow> _all = [];
  ActivityKind? _filter;
  _ActivityPeriod _period = _ActivityPeriod.day;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await context.read<SessionRepository>().closedWorkouts();
    if (!mounted) return;
    setState(() {
      _all = rows;
      _loaded = true;
    });
    context.read<StepService>().setRecordedToday(
          summarizePeriod(inLocalDay(rows, DateTime.now())).steps,
        );
  }

  List<WorkoutRow> _inPeriod(List<WorkoutRow> rows, DateTime now) {
    return switch (_period) {
      _ActivityPeriod.day => inLocalDay(rows, now),
      _ActivityPeriod.week => inLocalWeek(rows, now),
      _ActivityPeriod.month => inLocalMonth(rows, now),
    };
  }

  String get _periodEmptyCopy => switch (_period) {
        _ActivityPeriod.day => BalmiCopy.todayEmpty,
        _ActivityPeriod.week => BalmiCopy.weekEmpty,
        _ActivityPeriod.month => BalmiCopy.monthEmpty,
      };

  String get _periodSummaryTitle => switch (_period) {
        _ActivityPeriod.day => BalmiCopy.todayExercise,
        _ActivityPeriod.week => BalmiCopy.weekSummary,
        _ActivityPeriod.month => BalmiCopy.monthSummary,
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stepGoal = context.watch<StepGoalController>();
    final inPeriod = _inPeriod(_all, now);
    final filtered = inPeriod.where((r) => r.matchesFilter(_filter)).toList();
    // Summaries stay period-wide (home parity for today); sport filter scopes the log only.
    final todayExercise = summarizePeriod(inLocalDay(_all, now));
    final periodStats = summarizePeriod(inPeriod);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: BalmiColors.ink),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
            Expanded(
              child: Text(
                BalmiCopy.myActivity,
                style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PeriodTabs(
          value: _period,
          onChanged: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: 16),
        if (_period == _ActivityPeriod.day)
          TodayExerciseCard(
            stats: todayExercise,
            exerciseMinutes: stepGoal.exerciseMinutes,
            exerciseKm: stepGoal.exerciseKm,
          )
        else
          _PeriodSummaryCard(
            title: _periodSummaryTitle,
            stats: periodStats,
            emptyCopy: _periodEmptyCopy,
          ),
        const SizedBox(height: 20),
        Text(
          BalmiCopy.activityFilterSection,
          style: BalmiTheme.body(size: 13, weight: FontWeight.w800, color: BalmiColors.sub),
        ),
        const SizedBox(height: 8),
        ActivityPills(
          value: _filter ?? ActivityKind.auto,
          onChanged: (v) => setState(() => _filter = v == ActivityKind.auto ? null : v),
        ),
        const SizedBox(height: 22),
        Text(
          BalmiCopy.workoutLogTab,
          style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        if (!_loaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: BalmiColors.potato),
              ),
            ),
          )
        else if (filtered.isEmpty) ...[
          if (inPeriod.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                BalmiCopy.activityFilterEmpty,
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              ),
            ),
        ] else
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
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.value, required this.onChanged});

  final _ActivityPeriod value;
  final ValueChanged<_ActivityPeriod> onChanged;

  static const _items = <(_ActivityPeriod, String)>[
    (_ActivityPeriod.day, BalmiCopy.periodToday),
    (_ActivityPeriod.week, BalmiCopy.periodWeek),
    (_ActivityPeriod.month, BalmiCopy.periodMonth),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${BalmiCopy.periodToday} · ${BalmiCopy.periodWeek} · ${BalmiCopy.periodMonth}',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: BalmiColors.mist,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final item in _items)
              Expanded(
                child: _PeriodTab(
                  label: item.$2,
                  selected: value == item.$1,
                  onTap: () => onChanged(item.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? BalmiColors.paper : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Center(
              child: Text(
                label,
                style: BalmiTheme.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: selected ? BalmiColors.ink : BalmiColors.sub,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact week/month rollup — not a goal card, not a 3-period dump.
class _PeriodSummaryCard extends StatelessWidget {
  const _PeriodSummaryCard({
    required this.title,
    required this.stats,
    required this.emptyCopy,
  });

  final String title;
  final PeriodStats stats;
  final String emptyCopy;

  @override
  Widget build(BuildContext context) {
    final breakdown = ActivityKind.selectable
        .where((a) => !a.isAuto && (stats.byActivity[a] ?? 0) > 0)
        .map((a) => '${a.label} ${formatKm(stats.byActivity[a] ?? 0)}km')
        .join(' · ');

    return Semantics(
      label: stats.isEmpty
          ? '$title. $emptyCopy'
          : '$title ${stats.sessions}회 ${formatKm(stats.distM)}km ${formatElapsed(stats.duration)}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BalmiTheme.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w800, color: BalmiColors.sub),
            ),
            const SizedBox(height: 10),
            if (stats.isEmpty)
              Text(
                emptyCopy,
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              )
            else ...[
              Text(
                '${stats.sessions}회 · ${formatKm(stats.distM)}km · ${formatElapsed(stats.duration)}',
                style: BalmiTheme.num(size: 18),
              ),
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  breakdown,
                  style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
