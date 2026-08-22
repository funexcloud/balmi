import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/activity.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/balmi_wordmark.dart';
import '../../widgets/status_chips.dart';
import '../../widgets/trust_header.dart';
import '../session_detail/session_detail_screen.dart';
import 'recording_controller.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with WidgetsBindingObserver {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RecordingController>().nudgeGps();
    }
  }

  Future<void> _stop(RecordingController rec) async {
    final nav = Navigator.of(context);
    final id = await rec.stop();
    if (id == null) return;
    await nav.push(
      MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();
    final snap = rec.snapshot;
    final running = snap?.sport == 'run';
    final hint = rec.gpsHint;
    final speed = snap?.speedKmh ?? 0;
    final laps = snap?.lapCount ?? 0;
    final spec = snap?.trackSpecM;
    final specLabel = spec == null ? BalmiCopy.specFree : '${spec}m';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TrustHeader(
                  snapshot: snap,
                  waiting: (snap?.pointCount ?? 0) == 0,
                ),
                const SizedBox(height: 12),
                ActivityPills(
                  value: rec.activity,
                  onChanged: (v) => rec.setActivity(v),
                ),
                const SizedBox(height: 6),
                Text(
                  rec.activity.isAuto ? BalmiCopy.sportHint : BalmiCopy.sportHintManual,
                  style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    hint,
                    style: BalmiTheme.body(
                      size: 13,
                      color: (snap?.pointCount ?? 0) == 0
                          ? BalmiColors.plum
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    SportPill(
                      running: rec.activity == ActivityKind.run ||
                          rec.activity == ActivityKind.trail ||
                          running,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        BalmiCopy.sportHint,
                        style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(BalmiCopy.currentPace, style: BalmiTheme.tracked(size: 11.5, trackingEm: 0.2)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatPace(speed),
                    style: BalmiTheme.num(size: 74, height: 1.02),
                  ),
                ),
                const HeartbeatDivider(),
                Row(
                  children: [
                    LiveStat(
                      label: BalmiCopy.statDistance,
                      value: '${formatKm(snap?.totalDistM ?? 0)}km',
                    ),
                    const SizedBox(width: 26),
                    LiveStat(
                      label: BalmiCopy.statTime,
                      value: formatElapsed(rec.elapsed),
                    ),
                    const SizedBox(width: 26),
                    LiveStat(
                      label: BalmiCopy.statSpeed,
                      value: formatSpeedKmh(speed),
                    ),
                  ],
                ),
                if (snap?.trackMode == true) ...[
                  const SizedBox(height: 22),
                  _TrackCard(
                    specLabel: specLabel,
                    laps: laps,
                    lastLap: snap?.lastLapTimeS,
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: rec.paused ? rec.resumeLive : rec.pause,
                child: Text(rec.paused ? BalmiCopy.resumeLive : BalmiCopy.pause),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _stop(rec),
                child: const Text(BalmiCopy.stop),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.specLabel,
    required this.laps,
    required this.lastLap,
  });

  final String specLabel;
  final int laps;
  final double? lastLap;

  @override
  Widget build(BuildContext context) {
    final filled = laps <= 0 ? 0 : ((laps - 1) % 8) + 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BalmiColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${BalmiCopy.trackMode} · $specLabel',
                style: BalmiTheme.tracked(
                  size: 11.5,
                  trackingEm: 0.14,
                  color: BalmiColors.plum,
                  weight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                BalmiCopy.finishAuto,
                style: BalmiTheme.body(size: 10.5, color: BalmiColors.sub),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$laps', style: BalmiTheme.num(size: 42)),
              Text('바퀴', style: BalmiTheme.num(size: 19, weight: FontWeight.w700)),
              const SizedBox(width: 14),
              Text(
                BalmiCopy.lastLap,
                style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
              ),
              const SizedBox(width: 6),
              Text(
                lastLap == null ? '--\'--"' : formatLapClock(lastLap!),
                style: BalmiTheme.num(size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(8, (i) {
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i == 7 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: i < filled ? BalmiColors.amber : BalmiColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
