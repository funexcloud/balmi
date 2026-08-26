import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../domain/engines/record_status.dart';
import 'circle_action.dart';

Future<void> showRecordingAlertsSheet({
  required BuildContext context,
  required bool paused,
  required bool waitingGps,
  String? lastError,
  RecordSurvivalStatus? status,
}) {
  final survival = status;
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
              survival?.primaryLine ??
                  (paused ? BalmiCopy.pause : BalmiCopy.recordingLive),
              survival?.saveLine ??
                  (paused
                      ? BalmiCopy.recoverySavedHint
                      : BalmiCopy.deviceSaving),
            ),
            const SizedBox(height: 10),
            _line(
              BalmiCopy.gps,
              waitingGps
                  ? BalmiCopy.gpsSearching
                  : (survival?.gpsLine ?? BalmiCopy.waitingGpsShort),
            ),
            if (survival != null) ...[
              const SizedBox(height: 10),
              _line(
                '네트워크',
                survival.network == RecordLink.offline
                    ? BalmiCopy.offlineRecording
                    : survival.network == RecordLink.online
                        ? '연결됨'
                        : '상태 확인 중',
              ),
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
