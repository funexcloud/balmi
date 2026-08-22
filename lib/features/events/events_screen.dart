import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/workout_stats.dart';
import '../../domain/models/activity.dart';
import '../../widgets/balmi_app_bar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<EventRow> _events = [];
  List<WorkoutRow> _workouts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<SessionRepository>();
    final events = await repo.listEvents();
    final workouts = await repo.closedWorkouts();
    if (!mounted) return;
    setState(() {
      _events = events;
      _workouts = workouts;
    });
  }

  Future<void> _create() async {
    final name = TextEditingController();
    var km = true;
    var goal = 5.0;
    ActivityKind? filter;
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day);
    var end = start.add(const Duration(days: 7));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text(BalmiCopy.createEvent),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: name, decoration: const InputDecoration(labelText: '이름')),
                    const SizedBox(height: 8),
                    Text('기간: ${start.month}/${start.day} – ${end.month}/${end.day}'),
                    DropdownButton<ActivityKind?>(
                      value: filter,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('전체')),
                        ...ActivityKind.selectable
                            .where((a) => !a.isAuto)
                            .map((a) => DropdownMenuItem(value: a, child: Text(a.label))),
                      ],
                      onChanged: (v) => setLocal(() => filter = v),
                    ),
                    SwitchListTile(
                      title: Text(km ? '목표 거리(km)' : '목표 시간(분)'),
                      value: km,
                      onChanged: (v) => setLocal(() => km = v),
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: km ? 'km' : '분'),
                      onChanged: (v) => goal = double.tryParse(v) ?? goal,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('만들기')),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted) return;
    final title = name.text.trim().isEmpty ? '나의 대회' : name.text.trim();
    await context.read<SessionRepository>().createEvent(
          name: title,
          startsAt: start,
          endsAt: end,
          goalType: km ? 'distance_km' : 'duration_min',
          goalValue: goal,
          activityFilter: filter,
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(title: BalmiCopy.events),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: BalmiColors.plum,
        foregroundColor: BalmiColors.paper,
        label: const Text(BalmiCopy.createEvent),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        children: [
          Text(BalmiCopy.crewLater, style: BalmiTheme.body(size: 12, color: BalmiColors.sub)),
          const SizedBox(height: 10),
          if (_events.isEmpty)
            Text('만든 대회가 없습니다', style: BalmiTheme.body(size: 14, color: BalmiColors.sub)),
          for (final e in _events)
            _tile(e, now),
        ],
      ),
    );
  }

  Widget _tile(EventRow e, DateTime now) {
    final spec = EventSpec(
      id: e.id,
      name: e.name,
      startsAt: e.startsAt,
      endsAt: e.endsAt,
      activityFilter: e.activityFilter == 'all' ? null : ActivityKind.fromWire(e.activityFilter),
      goalType: e.goalType,
      goalValue: e.goalValue,
    );
    final current = eventProgress(spec, _workouts);
    final open = spec.isOpen(now);
    final ratio = spec.goalValue <= 0 ? 0.0 : (current / spec.goalValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BalmiColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.name, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
            Text(
              '${open ? BalmiCopy.eventOpen : BalmiCopy.eventClosed} · ${e.startsAt.month}/${e.startsAt.day}–${e.endsAt.month}/${e.endsAt.day}',
              style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: ratio, color: BalmiColors.plum, backgroundColor: BalmiColors.line),
            const SizedBox(height: 4),
            Text(
              '${current.toStringAsFixed(e.goalType == 'distance_km' ? 2 : 0)} / ${e.goalValue} ${e.goalType == 'distance_km' ? 'km' : '분'}',
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
            ),
          ],
        ),
      ),
    );
  }
}
