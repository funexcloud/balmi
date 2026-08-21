import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../data/db/app_database.dart';

Future<bool?> showRecoveryDialog(BuildContext context, Session session) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: const Text(BalmiCopy.recoveryTitle),
        content: Text(
          '${BalmiCopy.recoveryBody}\n\n시작 ${formatDateTime(session.startedAt)}',
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
