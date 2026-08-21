import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../data/stubs/future_features.dart';
import '../../widgets/trust_header.dart';
import '../history/history_screen.dart';
import '../recording/recording_controller.dart';
import '../recording/recording_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _trackMode = false;
  int? _specM = 400;

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(BalmiCopy.appName),
        actions: [
          IconButton(
            tooltip: BalmiCopy.history,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: BalmiCopy.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(BalmiCopy.oneLiner, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(BalmiCopy.positioning, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TrustHeader(
            snapshot: rec.snapshot,
            waiting: rec.isRecording && (rec.snapshot?.pointCount ?? 0) == 0,
          ),
          const SizedBox(height: 12),
          Text(BalmiCopy.trustAlways, style: Theme.of(context).textTheme.bodyMedium),
          if (rec.lastError != null) ...[
            const SizedBox(height: 12),
            Text(
              rec.lastError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(BalmiCopy.trackMode),
            subtitle: const Text('학교·공원 트랙에서 바퀴를 셉니다'),
            value: _trackMode,
            onChanged: rec.isRecording
                ? null
                : (v) => setState(() => _trackMode = v),
          ),
          if (_trackMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<int?>(
                initialValue: _specM,
                decoration: const InputDecoration(labelText: BalmiCopy.trackSpec),
                items: const [
                  DropdownMenuItem(value: 400, child: Text('400m')),
                  DropdownMenuItem(value: 300, child: Text('300m')),
                  DropdownMenuItem(value: 200, child: Text('200m')),
                  DropdownMenuItem(value: null, child: Text(BalmiCopy.specFree)),
                ],
                onChanged: rec.isRecording
                    ? null
                    : (v) => setState(() => _specM = v),
              ),
            ),
          FilledButton(
            onPressed: rec.isStarting
                ? null
                : rec.isRecording
                    ? () => _openRecording(context)
                    : () => _start(context, rec),
            child: Text(
              rec.isStarting
                  ? BalmiCopy.starting
                  : rec.isRecording
                      ? '기록 화면'
                      : BalmiCopy.start,
            ),
          ),
          if (rec.isRecording) ...[
            const SizedBox(height: 8),
            Text(
              '진행 중 · ${formatElapsed(DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(rec.snapshot!.startedAtMs)))}',
            ),
          ],
          const SizedBox(height: 32),
          if (!FutureFeatures.territoryEnabled && !FutureFeatures.crewEnabled)
            Text(
              'Release 1 · F1–F4',
              style: Theme.of(context).textTheme.labelMedium,
            ),
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context, RecordingController rec) async {
    final ok = await rec.start(trackMode: _trackMode, trackSpecM: _specM);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rec.lastError ?? BalmiCopy.startFailed)),
      );
      return;
    }
    _openRecording(context);
  }

  void _openRecording(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecordingScreen()),
    );
  }
}
