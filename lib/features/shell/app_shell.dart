import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/insets.dart';
import '../../core/theme.dart';
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
    final titles = [
      rec.isRecording ? BalmiCopy.recordingLive : BalmiCopy.readyToRecord,
      BalmiCopy.workoutLogTab,
      BalmiCopy.mapExplore,
      BalmiCopy.moreTab,
    ];

    return Scaffold(
      backgroundColor: BalmiColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  const BalmiWordmark(height: 26),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(titles[_tab], style: BalmiTheme.tracked()),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(rec)),
            _BottomNav(
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
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

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottom = systemNavBottomInset(context) + 16;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: BalmiColors.line)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: [
          _item(context, 0, BalmiCopy.recordTab),
          _item(context, 1, BalmiCopy.workoutLogTab),
          _item(context, 2, BalmiCopy.mapTab),
          _item(context, 3, BalmiCopy.moreTab),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, int i, String label) {
    final active = index == i;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(i),
        child: Container(
          margin: const EdgeInsets.only(top: -1),
          padding: const EdgeInsets.fromLTRB(0, 13, 0, 15),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: active ? BalmiColors.plum : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w800,
              color: active ? BalmiColors.plum : BalmiColors.sub,
            ),
          ),
        ),
      ),
    );
  }
}
