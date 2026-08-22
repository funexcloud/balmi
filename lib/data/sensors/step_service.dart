import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/copy.dart';

/// Hardware pedometer when available; otherwise recording-estimated steps.
class StepService extends ChangeNotifier {
  int? hardwareToday;
  int recordedToday = 0;
  StreamSubscription<StepCount>? _sub;

  bool get hasHardware => hardwareToday != null;
  int get displaySteps => hardwareToday ?? recordedToday;
  String get label => hasHardware ? BalmiCopy.todaySteps : BalmiCopy.recordingSteps;

  Future<void> start() async {
    try {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted && !status.isLimited) {
        return;
      }
      _sub = Pedometer.stepCountStream.listen(
        (e) {
          if (e.steps >= 0) {
            hardwareToday = e.steps;
            notifyListeners();
          }
        },
        onError: (_) {
          hardwareToday = null;
          notifyListeners();
        },
      );
    } catch (_) {
      hardwareToday = null;
    }
    notifyListeners();
  }

  void setRecordedToday(int steps) {
    if (recordedToday == steps) return;
    recordedToday = steps;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
