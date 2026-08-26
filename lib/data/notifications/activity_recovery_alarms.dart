import 'dart:async';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/copy.dart';

class ActivityRecoveryAlarmTap {
  const ActivityRecoveryAlarmTap({required this.checkId});

  final String checkId;
}

abstract class ActivityRecoveryAlarmPort {
  Stream<ActivityRecoveryAlarmTap> get taps;
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> cancel(String checkId);
  Future<void> scheduleRecheck({
    required String checkId,
    required DateTime at,
    required String body,
  });
}

class SilentActivityRecoveryAlarms implements ActivityRecoveryAlarmPort {
  final _taps = StreamController<ActivityRecoveryAlarmTap>.broadcast();

  @override
  Stream<ActivityRecoveryAlarmTap> get taps => _taps.stream;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> cancel(String checkId) async {}

  @override
  Future<void> scheduleRecheck({
    required String checkId,
    required DateTime at,
    required String body,
  }) async {}

  void emit(ActivityRecoveryAlarmTap tap) => _taps.add(tap);
}

/// Local one-shot recheck (~10–15 min). Same plugin family as meal-walk.
class ActivityRecoveryAlarms implements ActivityRecoveryAlarmPort {
  ActivityRecoveryAlarms({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<ActivityRecoveryAlarmTap>.broadcast();
  var _ready = false;

  static const _channelId = 'balmi_activity_recovery';

  static int noticeId(String checkId) =>
      8300 + (checkId.hashCode.abs() % 700);

  @override
  Stream<ActivityRecoveryAlarmTap> get taps => _taps.stream;

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const android = AndroidInitializationSettings('@drawable/ic_stat_balmi');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: _onResponse,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final res = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && res != null) {
      final tap = parsePayload(res.payload);
      if (tap != null) _taps.add(tap);
    }
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return true;
  }

  @override
  Future<void> cancel(String checkId) {
    return _plugin.cancel(noticeId(checkId));
  }

  @override
  Future<void> scheduleRecheck({
    required String checkId,
    required DateTime at,
    required String body,
  }) async {
    await cancel(checkId);
    var when = tz.TZDateTime.from(at.toLocal(), tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!when.isAfter(now)) {
      when = now.add(const Duration(seconds: 2));
    }
    await _plugin.zonedSchedule(
      noticeId(checkId),
      BalmiCopy.activityRecoveryTitle,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '회복 체크',
          channelDescription: '운동 후 회복 상태 다시 확인을 알려 줍니다.',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: Color(0xFFD9774A),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'balmi.recovery|$checkId',
    );
  }

  void _onResponse(NotificationResponse response) {
    final tap = parsePayload(response.payload);
    if (tap != null) _taps.add(tap);
  }

  static ActivityRecoveryAlarmTap? parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split('|');
    if (parts.length < 2) return null;
    if (parts[0] != 'balmi.recovery') return null;
    return ActivityRecoveryAlarmTap(checkId: parts[1]);
  }
}
