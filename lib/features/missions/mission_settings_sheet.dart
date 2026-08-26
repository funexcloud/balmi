import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../domain/engines/workout_stats.dart';
import '../../widgets/circle_action.dart';
import 'mission_settings_controller.dart';

Future<void> openMissionSettingsSheet(BuildContext context) {
  return showBalmiSheet<void>(
    context: context,
    builder: (ctx) => const MissionSettingsSheet(),
  );
}

/// Mission-scoped prefs only — not health habits / daily goals.
class MissionSettingsSheet extends StatelessWidget {
  const MissionSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<MissionSettingsController>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BalmiCopy.missionSettings,
              style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              BalmiCopy.missionSettingsHint,
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub, height: 1.4),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                BalmiCopy.missionReminder,
                style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
              ),
              subtitle: Text(
                BalmiCopy.missionReminderHint,
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              ),
              value: settings.reminderEnabled,
              activeThumbColor: BalmiColors.potato,
              onChanged: settings.setReminderEnabled,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                BalmiCopy.missionShowCompleted,
                style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
              ),
              subtitle: Text(
                BalmiCopy.missionShowCompletedHint,
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              ),
              value: settings.showCompleted,
              activeThumbColor: BalmiColors.potato,
              onChanged: settings.setShowCompleted,
            ),
            const Divider(height: 24, color: BalmiColors.line),
            Text(
              BalmiCopy.missionTypes,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              BalmiCopy.missionTypesHint,
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub, height: 1.4),
            ),
            const SizedBox(height: 4),
            for (final id in kKnownMissionIds)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  missionTitleForId(id),
                  style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                ),
                value: settings.isMissionEnabled(id),
                activeThumbColor: BalmiColors.potato,
                onChanged: (on) => settings.setMissionEnabled(id, on),
              ),
          ],
        ),
      ),
    );
  }
}
