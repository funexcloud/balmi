import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';

Future<bool?> showRecoveryDialog(BuildContext context, Session session) {
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
        content: Text(
          '${BalmiCopy.recoveryBody}\n\n시작 ${formatDateTime(session.startedAt)}',
          style: BalmiTheme.body(size: 14, height: 1.5),
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
