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
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        _row(context, BalmiCopy.myActivity, () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const Scaffold(
                backgroundColor: BalmiColors.paper,
                body: SafeArea(child: MyActivityScreen()),
              ),
            ),
          );
        }),
        _row(context, BalmiCopy.missions, () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MissionsScreen()));
        }),
        _row(context, BalmiCopy.events, () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsScreen()));
        }),
        _row(context, BalmiCopy.landTab, () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const Scaffold(
                backgroundColor: BalmiColors.paper,
                body: SafeArea(child: LandPreviewScreen()),
              ),
            ),
          );
        }),
        _row(context, BalmiCopy.settings, () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }),
      ],
    );
  }

  Widget _row(BuildContext context, String label, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(label, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
        trailing: const Icon(Icons.chevron_right, color: BalmiColors.sub),
        onTap: onTap,
      ),
    );
  }
}
