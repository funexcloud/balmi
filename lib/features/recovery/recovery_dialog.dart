import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/engines/recovery.dart';

/// Process-kill / crash recovery. Returns true = resume, false = save here.
Future<bool?> showRecoveryDialog(
  BuildContext context,
  RecoverableSession session,
) {
  final dist = session.displayDistM;
  final distLabel =
      dist < 1000 ? formatMeters(dist) : '${formatKm(dist)} km';
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: BalmiColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BalmiColors.line),
        ),
        title: Text(
          BalmiCopy.recoveryTitle,
          style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.activityLabel,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              distLabel,
              style: BalmiTheme.num(size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              formatElapsed(session.displayElapsed),
              style: BalmiTheme.num(size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              BalmiCopy.recoveryLastLabel,
              style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
            ),
            const SizedBox(height: 2),
            Text(
              formatClockAmPm(session.lastRecordedAt),
              style: BalmiTheme.body(size: 14, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              BalmiCopy.recoverySavedHint,
              style: BalmiTheme.body(size: 12, color: BalmiColors.sub, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(BalmiCopy.endHere),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(BalmiCopy.resumeRecording),
          ),
        ],
      );
    },
  );
}
