import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../activity/my_activity_screen.dart';
import '../events/events_screen.dart';
import '../land/land_preview_screen.dart';
import '../missions/missions_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, VoidCallback)>[
      (
        BalmiCopy.myActivity,
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const Scaffold(
                backgroundColor: BalmiColors.paper,
                body: SafeArea(child: MyActivityScreen()),
              ),
            ),
          );
        },
      ),
      (
        BalmiCopy.missions,
        () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MissionsScreen()));
        },
      ),
      (
        BalmiCopy.events,
        () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsScreen()));
        },
      ),
      (BalmiCopy.landTab, () => openLandPreview(context)),
      (
        BalmiCopy.settings,
        () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BalmiColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: BalmiColors.line),
                ListTile(
                  title: Text(rows[i].$1, style: BalmiTheme.body(size: 15, weight: FontWeight.w800)),
                  trailing: const Icon(Icons.chevron_right, color: BalmiColors.sub),
                  onTap: rows[i].$2,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
