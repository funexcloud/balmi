import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../data/recording/recording_snapshot.dart';
import 'status_chips.dart';

class TrustHeader extends StatelessWidget {
  const TrustHeader({
    super.key,
    required this.snapshot,
    this.waiting = false,
    this.showTrustLine = true,
  });

  final RecordingSnapshot? snapshot;
  final bool waiting;
  final bool showTrustLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RecordingStatusChips(snapshot: snapshot, waiting: waiting),
        if (showTrustLine) ...[
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
