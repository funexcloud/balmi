import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/workout_stats.dart';
import '../../widgets/balmi_app_bar.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SessionRepository>();
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(title: BalmiCopy.missions),
      body: FutureBuilder<List<WorkoutRow>>(
        future: repo.closedWorkouts(),
        builder: (context, snap) {
          final missions = missionPresets(snap.data ?? [], DateTime.now());
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              for (final m in missions) _MissionTile(mission: m),
            ],
          );
        },
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});

  final MissionSnapshot mission;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BalmiTheme.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(mission.title, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
                ),
                if (mission.done)
                  const Icon(Icons.check_circle, color: BalmiColors.sage),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: mission.ratio,
              color: BalmiColors.potato,
              backgroundColor: BalmiColors.line,
            ),
            const SizedBox(height: 6),
            Text(
              '${mission.current.toStringAsFixed(mission.unit == 'km' ? 2 : 0)} / ${mission.target.toStringAsFixed(0)} ${mission.unit}',
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
            ),
          ],
        ),
      ),
    );
  }
}
