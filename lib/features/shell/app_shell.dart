import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../widgets/balmi_dock.dart';
import '../../widgets/balmi_wordmark.dart';
import '../home/home_screen.dart';
import '../map/map_explore_screen.dart';
import '../more/more_screen.dart';
import '../recording/recording_controller.dart';
import '../recording/recording_screen.dart';
import '../workouts/workout_log_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();

    // Floating dock overlays the bottom; pad the body by [BalmiDock.extent]
    // so recording sheets / CTAs lay out above it instead of under it.
    final dockExtent = BalmiDock.extent(context);

    return Scaffold(
      backgroundColor: BalmiColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 14, 24, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BalmiWordmark(height: 38),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: dockExtent),
                      child: _body(rec),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: BalmiDock(
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(RecordingController rec) {
    return switch (_tab) {
      1 => const WorkoutLogScreen(),
      2 => const MapExploreScreen(),
      3 => const MoreScreen(),
      _ => rec.isRecording ? const RecordingScreen() : const HomeScreen(),
    };
  }
}
