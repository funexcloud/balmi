import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// Cadence from a 10s peak window. Sparse peaks (2–6 steps) look like
/// "standing" to the motion filter; treat those as unknown instead.
double? trustedCadenceSpm({
  required int stepCount,
  required Duration window,
  double minTrustedSpm = 40,
}) {
  if (stepCount < 2 || window.inSeconds <= 0) return null;
  final spm = stepCount * (60 / window.inSeconds);
  if (spm < minTrustedSpm) return null;
  return spm;
}

/// Step-ish cadence (spm) from linear acceleration peaks.
class CadenceEngine {
  CadenceEngine({
    this.window = const Duration(seconds: 10),
    this.peakThreshold = 1.15,
    this.minStepGap = const Duration(milliseconds: 280),
  });

  final Duration window;
  final double peakThreshold;
  final Duration minStepGap;

  StreamSubscription<UserAccelerometerEvent>? _sub;
  final List<DateTime> _steps = [];
  DateTime? _lastStep;
  double? _lastMag;
  bool _armed = true;

  double? spm;
  int totalSteps = 0;

  Future<void> start() async {
    await stop();
    _sub = userAccelerometerEventStream().listen((e) {
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      final now = DateTime.now();
      if (_armed &&
          _lastMag != null &&
          mag > peakThreshold &&
          _lastMag! <= peakThreshold) {
        if (_lastStep == null || now.difference(_lastStep!) >= minStepGap) {
          _steps.add(now);
          _lastStep = now;
          totalSteps += 1;
        }
        _armed = false;
      }
      if (mag < peakThreshold * 0.7) {
        _armed = true;
      }
      _lastMag = mag;
      _prune(now);
      spm = trustedCadenceSpm(
        stepCount: _steps.length,
        window: window,
      );
    }, onError: (Object _, StackTrace _) {});
  }

  void _prune(DateTime now) {
    final cut = now.subtract(window);
    _steps.removeWhere((t) => t.isBefore(cut));
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _steps.clear();
    totalSteps = 0;
    spm = null;
    _lastStep = null;
    _lastMag = null;
    _armed = true;
  }
}
