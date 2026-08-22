import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/workout_stats.dart';
import '../session_detail/session_detail_screen.dart';

class WorkoutLogScreen extends StatelessWidget {
  const WorkoutLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SessionRepository>();
    return FutureBuilder<List<WorkoutRow>>(
      future: repo.closedWorkouts(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: BalmiColors.plum));
        }
        if (items.isEmpty) {
          return Center(
            child: Text('아직 끝난 기록이 없어요', style: BalmiTheme.body(size: 15, color: BalmiColors.sub)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = items[i];
            final laps = r.laps > 0 ? ' · ${r.laps}바퀴' : '';
            return Card(
              child: ListTile(
                title: Text(
                  '${formatDateTime(r.startedAt)} · ${r.activity.label}',
                  style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${formatKm(r.totalDistM)}km · ${formatElapsed(r.duration)} · ${formatPace(r.paceKmh)}$laps',
                  style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SessionDetailScreen(sessionId: r.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
