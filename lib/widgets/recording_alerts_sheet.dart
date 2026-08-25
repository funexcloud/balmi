import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import 'circle_action.dart';

Future<void> showRecordingAlertsSheet({
  required BuildContext context,
  required bool paused,
  required bool waitingGps,
  String? lastError,
}) {
  return showBalmiSheet(
    context: context,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              BalmiCopy.recordingAlerts,
              style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _line(
              paused ? BalmiCopy.pause : BalmiCopy.recordingLive,
              paused
                  ? '기록이 멈춰 있습니다. 포인트는 기기에 남아 있습니다.'
                  : BalmiCopy.trustAlways,
            ),
            if (waitingGps) ...[
              const SizedBox(height: 10),
              _line(BalmiCopy.gps, BalmiCopy.waitingGps),
            ],
            if (lastError != null && lastError.isNotEmpty) ...[
              const SizedBox(height: 10),
              _line(BalmiCopy.startFailed, lastError),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined, color: BalmiColors.ink),
              title: Text(
                BalmiCopy.notificationPermission,
                style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
              ),
              onTap: () => Permission.notification.request(),
            ),
          ],
        ),
      );
    },
  );
}

Widget _line(String title, String body) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: BalmiTheme.body(size: 14, weight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(body, style: BalmiTheme.body(size: 13, color: BalmiColors.sub)),
    ],
  );
}
