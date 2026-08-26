import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../data/recording/recording_snapshot.dart';
import '../domain/engines/record_status.dart';
import 'status_chips.dart';

class TrustHeader extends StatelessWidget {
  const TrustHeader({
    super.key,
    required this.snapshot,
    this.waiting = false,
    this.showTrustLine = false,
    this.status,
  });

  final RecordingSnapshot? snapshot;
  final bool waiting;
  final bool showTrustLine;
  final RecordSurvivalStatus? status;

  @override
  Widget build(BuildContext context) {
    final survival = status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RecordingStatusChips(snapshot: snapshot, waiting: waiting),
        if (survival != null && survival.recording) ...[
          const SizedBox(height: 6),
          _StatusLine(text: survival.primaryLine),
          const SizedBox(height: 2),
          _StatusLine(
            text: survival.saveLine,
            muted: true,
          ),
        ] else if (showTrustLine) ...[
          const SizedBox(height: 6),
          Text(
            BalmiCopy.trustAlways,
            style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
          ),
        ],
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: BalmiTheme.body(
          size: 11,
          weight: muted ? FontWeight.w500 : FontWeight.w700,
          color: muted ? BalmiColors.sub : BalmiColors.ink,
        ),
      ),
    );
  }
}
