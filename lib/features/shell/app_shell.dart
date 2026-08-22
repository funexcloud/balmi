import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/insets.dart';
import '../../core/theme.dart';
import '../../widgets/balmi_wordmark.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../land/land_preview_screen.dart';
import '../recording/recording_controller.dart';
import '../recording/recording_screen.dart';
import '../settings/settings_screen.dart';

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
    final headerRight = _tab == 1
        ? BalmiCopy.registryEyebrow
        : rec.isRecording
            ? BalmiCopy.recordingLive
            : BalmiCopy.readyToRecord;

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
                  if (_tab == 0 && !rec.isRecording) ...[
                    IconButton(
                      tooltip: BalmiCopy.history,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, color: BalmiColors.ink),
                    ),
                    IconButton(
                      tooltip: BalmiCopy.settings,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: BalmiColors.ink,
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        headerRight,
                        style: BalmiTheme.tracked(),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? rec.isRecording
                      ? const RecordingScreen()
                      : const HomeScreen()
                  : const LandPreviewScreen(),
            ),
            _BottomNav(
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ],
        ),
      ),
    );
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
          _item(context, 1, BalmiCopy.landTab),
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
              size: 15,
              weight: FontWeight.w800,
              color: active ? BalmiColors.plum : BalmiColors.sub,
            ),
          ),
        ),
      ),
    );
  }
}
