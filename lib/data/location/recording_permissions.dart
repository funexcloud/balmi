import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/copy.dart';

/// Runtime checks required before GPS recording and a location FGS can start.
class RecordingPermissions {
  RecordingPermissions._();

  /// Returns a user-facing Korean error, or null if recording may start.
  static Future<String?> ensure() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        return BalmiCopy.locationOff;
      }
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return BalmiCopy.locationDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return BalmiCopy.locationDeniedForever;
    }

    if (Platform.isAndroid) {
      final n = await FlutterForegroundTask.checkNotificationPermission();
      if (n != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    }

    return null;
  }
}
