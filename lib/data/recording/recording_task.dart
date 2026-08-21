import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Foreground-service callback. GPS + SQLite run on the UI isolate
/// ([kFgRecorderKey] = `main`). This isolate only keeps the process alive.
const kFgRecorderKey = 'recorder';
const kFgDbPathKey = 'dbPath';
const kFgSessionIdKey = 'sessionId';
const kFgTrackModeKey = 'trackMode';
const kFgTrackSpecKey = 'trackSpecM';

/// Entry point for the Android foreground-service isolate.
@pragma('vm:entry-point')
void recordingStartCallback() {
  FlutterForegroundTask.setTaskHandler(RecordingTaskHandler());
}

class RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Intentionally empty: recording is owned by the UI isolate.
    // Geolocator.getPositionStream in this isolate often never emits.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
