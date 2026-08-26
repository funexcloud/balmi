import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/copy.dart';
import '../repositories/session_repository.dart';

const _kvBaselineDay = 'step_hw_baseline_day';
const _kvBaselineRaw = 'step_hw_baseline_raw';

/// Local calendar day key for persisted hardware baselines.
String stepLocalDayKey(DateTime now) {
  final d = now.toLocal();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Pedometer raw counts are since boot; subtract a daily baseline.
int hardwareStepsToday({required int raw, required int baseline}) {
  return (raw - baseline).clamp(0, 1 << 30);
}

/// Prefer the larger of sensor-derived and workout-derived counts for today.
int mergeTodaySteps({required int? hardwareToday, required int recordedToday}) {
  if (hardwareToday == null) return recordedToday;
  return hardwareToday > recordedToday ? hardwareToday : recordedToday;
}

/// Hardware pedometer when available; otherwise recording-estimated steps.
class StepService extends ChangeNotifier {
  StepService({SessionRepository? repo}) : _repo = repo;

  final SessionRepository? _repo;
  int? hardwareToday;
  int recordedToday = 0;
  int? _hardwareBaseline;
  String? _baselineDay;
  StreamSubscription<StepCount>? _sub;

  bool get hasHardware => hardwareToday != null;
  int get displaySteps =>
      mergeTodaySteps(hardwareToday: hardwareToday, recordedToday: recordedToday);
  String get label => hasHardware ? BalmiCopy.todaySteps : BalmiCopy.recordingSteps;

  Future<void> start() async {
    await _loadBaseline();
    try {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted && !status.isLimited) {
        return;
      }
      _sub = Pedometer.stepCountStream.listen(
        _onHardwareStep,
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

  Future<void> _loadBaseline() async {
    final repo = _repo;
    if (repo == null) return;
    final day = stepLocalDayKey(DateTime.now());
    final savedDay = await repo.getKv(_kvBaselineDay);
    if (savedDay != day) return;
    final raw = int.tryParse(await repo.getKv(_kvBaselineRaw) ?? '');
    if (raw == null) return;
    _baselineDay = day;
    _hardwareBaseline = raw;
  }

  Future<void> _persistBaseline(int raw, String day) async {
    final repo = _repo;
    if (repo == null) return;
    await repo.putKv(_kvBaselineDay, day);
    await repo.putKv(_kvBaselineRaw, raw.toString());
  }

  Future<void> _onHardwareStep(StepCount event) async {
    final raw = event.steps;
    if (raw < 0) return;
    final day = stepLocalDayKey(DateTime.now());
    if (_baselineDay != day || _hardwareBaseline == null) {
      _baselineDay = day;
      _hardwareBaseline = raw;
      await _persistBaseline(raw, day);
    }
    final next = hardwareStepsToday(raw: raw, baseline: _hardwareBaseline!);
    if (hardwareToday == next) return;
    hardwareToday = next;
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
