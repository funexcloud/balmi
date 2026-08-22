import 'package:intl/intl.dart';

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

String formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

/// Current pace from km/h, mockup form `m'ss"`. Slow/unknown → `--'--"`.
String formatPace(double speedKmh) {
  if (speedKmh <= 0.5) return '--\'--"';
  final p = 60 / speedKmh;
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

