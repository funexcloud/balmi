import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../widgets/trust_header.dart';
import 'recording_controller.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecordingController>();
    final snap = rec.snapshot;
    final started = snap == null
        ? Duration.zero
        : DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(snap.startedAtMs),
          );
    return Scaffold(
      appBar: AppBar(title: const Text(BalmiCopy.appName)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrustHeader(snapshot: snap),
            const SizedBox(height: 12),
            Text(BalmiCopy.trustAlways),
            const Spacer(),
            Text(
              formatElapsed(started),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatKm(snap?.totalDistM ?? 0)} km',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              (snap?.sport == 'run') ? BalmiCopy.run : BalmiCopy.walk,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (snap?.trackMode == true) ...[
              const SizedBox(height: 8),
              Text(
                '${snap!.lapCount}바퀴',
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            Text(
              walkRunResultLine(
                walkDuration: Duration.zero,
                walkMeters: snap?.walkDistM ?? 0,
                runDuration: Duration.zero,
                runMeters: snap?.runDistM ?? 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                await rec.stop();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text(BalmiCopy.stop),
            ),
          ],
        ),
      ),
    );
  }
}
