import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/stubs/future_features.dart';
import '../../widgets/trust_header.dart';
import '../recording/recording_controller.dart';

/// Idle 기록 tab: real start (permissions + track spec), not mock GPS.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _trackMode = false;
  int? _specM = 400;

  Future<void> _start(RecordingController rec) async {
    final ok = await rec.start(trackMode: _trackMode, trackSpecM: _specM);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rec.lastError ?? BalmiCopy.startFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            children: [
              Text(BalmiCopy.oneLiner, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                BalmiCopy.positioning,
                style: BalmiTheme.body(size: 14, color: BalmiColors.sub),
              ),
              const SizedBox(height: 16),
              TrustHeader(snapshot: rec.snapshot, waiting: false),
              if (rec.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  rec.lastError!,
                  style: BalmiTheme.body(
                    size: 13,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: BalmiColors.paper,
                activeTrackColor: BalmiColors.plum,
                title: Text(BalmiCopy.trackMode, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
                subtitle: Text(
                  '학교·공원 트랙에서 바퀴를 셉니다',
                  style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                ),
                value: _trackMode,
                onChanged: rec.isStarting ? null : (v) => setState(() => _trackMode = v),
              ),
              if (_trackMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int?>(
                    initialValue: _specM,
                    decoration: InputDecoration(
                      labelText: BalmiCopy.trackSpec,
                      labelStyle: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: BalmiColors.line),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 400, child: Text('400m')),
                      DropdownMenuItem(value: 300, child: Text('300m')),
                      DropdownMenuItem(value: 200, child: Text('200m')),
                      DropdownMenuItem(value: null, child: Text(BalmiCopy.specFree)),
                    ],
                    onChanged: rec.isStarting ? null : (v) => setState(() => _specM = v),
                  ),
                ),
              if (!FutureFeatures.territoryEnabled && !FutureFeatures.crewEnabled)
                Text(
                  'Release 1 · F1–F4',
                  style: BalmiTheme.tracked(size: 11, trackingEm: 0.08, color: BalmiColors.sub),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: FilledButton(
            onPressed: rec.isStarting ? null : () => _start(rec),
            child: Text(rec.isStarting ? BalmiCopy.starting : BalmiCopy.start),
          ),
        ),
      ],
    );
  }
}
