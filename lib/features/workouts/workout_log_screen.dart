import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/workout_stats.dart';
import '../../widgets/session_row.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: BalmiColors.line),
          itemBuilder: (context, i) {
            final r = items[i];
            return SessionRow(
              startedAt: r.startedAt,
              activityLabel: r.activity.label,
              distM: r.totalDistM,
              trailing: formatElapsed(r.duration),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SessionDetailScreen(sessionId: r.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
