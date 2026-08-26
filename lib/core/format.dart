import 'package:intl/intl.dart';

import '../domain/engines/live_speed.dart';

String formatKm(double meters) => (meters / 1000).toStringAsFixed(2);

String formatMeters(double meters) => '${meters.round()}m';

/// Result copy: 걷기 Xm Ykm / 뛰기 Xm Ykm — X is minutes, Y is km.
String walkRunResultLine({
  required Duration walkDuration,
  required double walkMeters,
  required Duration runDuration,
  required double runMeters,
}) {
  return '걷기 ${walkDuration.inMinutes}m ${formatKm(walkMeters)}km / '
      '뛰기 ${runDuration.inMinutes}m ${formatKm(runMeters)}km';
}

String formatLapTts({required int lapNo, required double lapTimeS}) {
  final total = lapTimeS.round().clamp(0, 24 * 3600);
  final m = total ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  return '$lapNo바퀴, $m분 $ss초';
}

String formatDateTime(DateTime ts) {
  return DateFormat('yyyy.MM.dd HH:mm').format(ts.toLocal());
}

/// Recovery UI clock, e.g. `오후 7:42`.
String formatClockAmPm(DateTime ts) {
  final local = ts.toLocal();
  final h = local.hour;
  final m = local.minute.toString().padLeft(2, '0');
  if (h < 12) {
    final hour = h == 0 ? 12 : h;
    return '오전 $hour:$m';
  }
  final hour = h == 12 ? 12 : h - 12;
  return '오후 $hour:$m';
}

String formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

/// Foreground notification body. Never uses 점 (reads as a score).
String formatRecordingNotification({
  required Duration elapsed,
  required double distM,
}) {
  return '기록 ${formatElapsed(elapsed)} · ${formatKm(distM)}km';
}

/// Current pace from km/h, mockup form `m'ss"`. Slow/unknown → `--'--"`.
String formatPace(double speedKmh) {
  final p = paceMinPerKm(speedKmh);
  if (p == null) return '--\'--"';
  var m = p.floor();
  var s = ((p - m) * 60).round();
  if (s == 60) {
    m += 1;
    s = 0;
  }
  return '$m\'${s.toString().padLeft(2, '0')}"';
}

String formatLapClock(double lapTimeS) {
  final total = lapTimeS.round().clamp(0, 24 * 3600);
  final m = total ~/ 60;
  final s = total % 60;
  return '$m\'${s.toString().padLeft(2, '0')}"';
}

String formatSpeedKmh(double speedKmh) => '${speedKmh.toStringAsFixed(1)}km/h';

/// Thousands-separated step counts for hero and settings.
String formatSteps(int steps) => NumberFormat('#,###').format(steps);

/// Area for 「내 땅」 rewards — whole ㎡ with thousands separators.
String formatAreaM2(double m2) => '${NumberFormat('#,###').format(m2.round())}㎡';

