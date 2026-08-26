import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../domain/engines/workout_stats.dart';
import '../../widgets/balmi_app_bar.dart';
import 'mission_settings_controller.dart';

Future<void> openMissionSettingsSheet(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const MissionSettingsScreen()),
  );
}

/// Mission-scoped prefs only — not health habits / daily goals.
class MissionSettingsScreen extends StatelessWidget {
  const MissionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<MissionSettingsController>();
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(title: BalmiCopy.missionSettings),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
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
    );
  }
}

/// Kept for tests / call sites that refer to the settings surface by sheet name.
typedef MissionSettingsSheet = MissionSettingsScreen;
