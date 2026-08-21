import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class OemBattery {
  static const channel = MethodChannel('im.balmi.app/oem');

  static Future<String> manufacturer() async {
    if (!Platform.isAndroid) return 'unknown';
    try {
      return await channel.invokeMethod<String>('manufacturer') ?? 'unknown';
    } on PlatformException {
      return 'unknown';
    }
  }

  static Future<bool> isIgnoringOptimizations() async {
    if (!Platform.isAndroid) return true;
    return FlutterForegroundTask.isIgnoringBatteryOptimizations;
  }

  static Future<void> requestIgnore() async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  static Future<bool> openOemSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await channel.invokeMethod<bool>('openOemBatterySettings') ??
          false;
    } on PlatformException {
      return FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
    }
  }

  static String familyLabel(String manufacturer) {
    final m = manufacturer.toLowerCase();
    if (m.contains('samsung')) return 'Samsung';
    if (m.contains('xiaomi') ||
        m.contains('redmi') ||
        m.contains('poco') ||
        m.contains('blackshark')) {
      return 'Xiaomi';
    }
    if (m.contains('huawei') || m.contains('honor')) return 'Huawei';
    if (m.contains('oppo') || m.contains('realme') || m.contains('oneplus')) {
      return 'Oppo';
    }
    if (m.contains('vivo') || m.contains('iqoo')) return 'Vivo';
    if (m.contains('google') || m.contains('pixel')) return 'Pixel';
    return manufacturer;
  }
}
