import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../activity/my_activity_screen.dart';
import '../events/events_screen.dart';
import '../land/farm_preview_screen.dart';
import '../land/land_map_screen.dart';
import '../missions/missions_screen.dart';
import '../settings/health_habits_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _MoreGroup(
          rows: [
            (
              Icons.person_outline,
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
              Icons.flag_outlined,
              BalmiCopy.missions,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MissionsScreen()),
                );
              },
            ),
            (
              Icons.emoji_events_outlined,
              BalmiCopy.events,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EventsScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MoreGroup(
          rows: [
            (
              Icons.landscape_outlined,
              BalmiCopy.landTab,
              () => openLandMap(context),
            ),
            (
              Icons.agriculture_outlined,
              BalmiCopy.farmTitle,
              () => openFarmPreview(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MoreGroup(
          rows: [
            (
              Icons.favorite_outline,
              BalmiCopy.mealWalkHealthSection,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HealthHabitsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MoreGroup(
          rows: [
            (
              Icons.settings_outlined,
              BalmiCopy.settings,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          BalmiCopy.mapCredit,
          style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MoreGroup extends StatelessWidget {
  const _MoreGroup({required this.rows});

  final List<(IconData, String, VoidCallback)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BalmiColors.mist,
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: BalmiColors.line),
              ListTile(
                leading: Icon(rows[i].$1, color: BalmiColors.ink),
                title: Text(
                  rows[i].$2,
                  style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                ),
                trailing: const Icon(Icons.chevron_right, color: BalmiColors.sub),
                onTap: rows[i].$3,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
