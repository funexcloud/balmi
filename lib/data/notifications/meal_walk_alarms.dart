import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../domain/engines/meal_walk.dart';

enum MealWalkAlarmKind { meal, walk }

class MealWalkAlarmTap {
  const MealWalkAlarmTap({required this.kind, this.mealType, this.sessionId});

  final MealWalkAlarmKind kind;
  final MealType? mealType;
  final String? sessionId;
}

abstract class MealWalkAlarmPort {
  Stream<MealWalkAlarmTap> get taps;
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> cancelAll();
  Future<void> cancelWalk(String sessionId);
  Future<void> scheduleDailyMeals(MealSchedule schedule);
  Future<void> scheduleWalkPrompt({
    required String sessionId,
    required DateTime at,
  });
}

class SilentMealWalkAlarms implements MealWalkAlarmPort {
  final _taps = StreamController<MealWalkAlarmTap>.broadcast();

  @override
  Stream<MealWalkAlarmTap> get taps => _taps.stream;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelWalk(String sessionId) async {}

  @override
  Future<void> scheduleDailyMeals(MealSchedule schedule) async {}

  @override
  Future<void> scheduleWalkPrompt({
    required String sessionId,
    required DateTime at,
  }) async {}

  void emit(MealWalkAlarmTap tap) => _taps.add(tap);
}

/// Local schedule so a closed app can still ring. No FCM in this client.
class MealWalkAlarms implements MealWalkAlarmPort {
  MealWalkAlarms({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<MealWalkAlarmTap>.broadcast();
  var _ready = false;

  @override
  Stream<MealWalkAlarmTap> get taps => _taps.stream;

  static const _channelId = 'balmi_meal_walk';
  static const _mealIds = {
    MealType.breakfast: 7101,
    MealType.lunch: 7102,
    MealType.dinner: 7103,
  };

  static int walkNoticeId(String sessionId) =>
      7200 + (sessionId.hashCode.abs() % 800);

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
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  @override
  Future<void> cancelWalk(String sessionId) {
    return _plugin.cancel(walkNoticeId(sessionId));
  }

  @override
  Future<void> scheduleDailyMeals(MealSchedule schedule) async {
    for (final type in MealType.values) {
      await _plugin.cancel(_mealIds[type]!);
      if (!schedule.featureEnabled) continue;
      final clock = schedule.timeOf(type);
      await _plugin.zonedSchedule(
        _mealIds[type]!,
        BalmiCopy.mealWalkTitle,
        BalmiCopy.mealWalkStartPrompt,
        _next(clock.hour, clock.minute),
        _details(sound: false),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'balmi.meal|${type.wire}',
      );
    }
  }

  @override
  Future<void> scheduleWalkPrompt({
    required String sessionId,
    required DateTime at,
  }) async {
    var when = tz.TZDateTime.from(at.toLocal(), tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!when.isAfter(now)) {
      when = now.add(const Duration(seconds: 2));
    }
    await _plugin.zonedSchedule(
      walkNoticeId(sessionId),
      BalmiCopy.mealWalkTitle,
      BalmiCopy.mealWalkGo,
      when,
      _details(sound: true),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'balmi.walk|$sessionId',
    );
  }

  NotificationDetails _details({required bool sound}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        '혈당 워킹 알림',
        channelDescription: '식사 시간과 식후 걷기를 알려 줍니다.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound,
        enableVibration: true,
        color: BalmiColors.potato,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: sound,
      ),
    );
  }

  tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onResponse(NotificationResponse response) {
    final tap = parsePayload(response.payload);
    if (tap != null) _taps.add(tap);
  }

  static MealWalkAlarmTap? parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split('|');
    if (parts.length < 2) return null;
    if (parts[0] == 'balmi.meal') {
      return MealWalkAlarmTap(
        kind: MealWalkAlarmKind.meal,
        mealType: MealType.fromWire(parts[1]),
      );
    }
    if (parts[0] == 'balmi.walk') {
      return MealWalkAlarmTap(
        kind: MealWalkAlarmKind.walk,
        sessionId: parts[1],
      );
    }
    return null;
  }
}
