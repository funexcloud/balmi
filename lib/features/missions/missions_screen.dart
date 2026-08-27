import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/workout_stats.dart';
import '../../widgets/balmi_app_bar.dart';
import 'mission_settings_controller.dart';
import 'mission_settings_sheet.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SessionRepository>();
    final settings = context.watch<MissionSettingsController>();
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: BalmiAppBar(
        title: BalmiCopy.missions,
        actions: [
          IconButton(
            tooltip: BalmiCopy.missionSettings,
            icon: const Icon(Icons.tune),
            onPressed: () => openMissionSettingsSheet(context),
          ),
        ],
      ),
      body: FutureBuilder<List<WorkoutRow>>(
        future: repo.closedWorkouts(),
        builder: (context, snap) {
          final presets = missionPresets(snap.data ?? [], DateTime.now());
          final missions = settings.filterMissions(presets);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_outlined, color: BalmiColors.potato),
                title: Text(
                  BalmiCopy.missionSettings,
                  style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                ),
                subtitle: Text(
                  BalmiCopy.missionSettingsHint,
                  style: BalmiTheme.body(size: 12, color: BalmiColors.sub, height: 1.35),
                ),
                trailing: const Icon(Icons.chevron_right, color: BalmiColors.sub),
                onTap: () => openMissionSettingsSheet(context),
              ),
              const SizedBox(height: 4),
              const Divider(color: BalmiColors.line),
              const SizedBox(height: 8),
              if (missions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    BalmiCopy.missionEmptyFiltered,
                    style: BalmiTheme.body(size: 14, color: BalmiColors.sub, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                )
              else
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
