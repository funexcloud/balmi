import 'dart:math' as math;

import 'distance.dart';

/// Share card visual / disclosure level. VASA stays locked until real data + safe copy.
enum ActivityShareStyle {
  map,
  record,
  minimal,
  vasa;

  bool get isAvailable => this != vasa;

  String get wire => name;
}

/// Local-only share payload. No server round-trip in Light MVP.
final class ActivityShareSummary {
  const ActivityShareSummary({
    required this.sessionId,
    required this.shareId,
    required this.style,
    required this.activityLabel,
    required this.distanceM,
    required this.duration,
    required this.steps,
    required this.headline,
    required this.tagline,
    required this.deepLink,
    required this.hideStartEnd,
    required this.includeMap,
    required this.hideRadiusM,
    this.avgPaceLabel,
  });

  final String sessionId;
  final String shareId;
  final ActivityShareStyle style;
  final String activityLabel;
  final double distanceM;
  final Duration duration;
  final int steps;
  final String? avgPaceLabel;
  final String headline;
  final String tagline;
  final String deepLink;
  final bool hideStartEnd;
  final bool includeMap;
  final double hideRadiusM;
}

/// Public share host. Stub only — no hosted page yet.
const kActivityShareHost = 'https://balmi.im';

/// Default home-area redaction radius (meters). Spec allows 200–500.
const kDefaultShareHideRadiusM = 300.0;

/// Builds a stable, opaque-looking token from a local session id (no server).
String activityShareIdFromSession(String sessionId) {
  final compact = sessionId.replaceAll('-', '').toUpperCase();
  if (compact.length >= 8) return compact.substring(0, 8);
  if (compact.isEmpty) return 'LOCAL000';
  return compact.padRight(8, '0');
}

String activityShareDeepLink(String shareId) =>
    '$kActivityShareHost/a/$shareId';

String? averagePaceLabel({
  required double distanceM,
  required Duration duration,
}) {
  final hours = duration.inMilliseconds / 3600000.0;
  if (hours <= 0 || distanceM <= 0) return null;
  final kmh = (distanceM / 1000) / hours;
  if (kmh <= 0.5) return null;
  final pace = 60 / kmh;
  var m = pace.floor();
  var s = ((pace - m) * 60).round();
  if (s == 60) {
    m += 1;
    s = 0;
  }
  return "$m'${s.toStringAsFixed(0).padLeft(2, '0')}\"";
}

String activityShareHeadline({
  required ActivityShareStyle style,
  required String activityLabel,
  required double distanceM,
}) {
  final km = (distanceM / 1000).toStringAsFixed(2);
  switch (style) {
    case ActivityShareStyle.minimal:
      return '$km km';
    case ActivityShareStyle.map:
      return '오늘도 하나의 길을 남겼습니다.';
    case ActivityShareStyle.record:
    case ActivityShareStyle.vasa:
      return '오늘 $km km $activityLabel했습니다.';
  }
}

/// Brand tagline for share surfaces. No medical claims.
String activityShareTagline(ActivityShareStyle style) {
  switch (style) {
    case ActivityShareStyle.map:
      return '단 한 걸음도 잃어버리지 않도록.';
    case ActivityShareStyle.minimal:
      return '기록은 멈추지 않도록.';
    case ActivityShareStyle.record:
    case ActivityShareStyle.vasa:
      return '걸음은 멈춰도,\n기록은 멈추지 않도록.';
  }
}

ActivityShareSummary buildActivityShareSummary({
  required String sessionId,
  required ActivityShareStyle style,
  required String activityLabel,
  required double distanceM,
  required Duration duration,
  required int steps,
  bool hideStartEnd = true,
  bool? includeMap,
  double hideRadiusM = kDefaultShareHideRadiusM,
}) {
  final effectiveStyle =
      style.isAvailable ? style : ActivityShareStyle.record;
  final shareId = activityShareIdFromSession(sessionId);
  final mapOn = includeMap ?? (effectiveStyle == ActivityShareStyle.map);
  return ActivityShareSummary(
    sessionId: sessionId,
    shareId: shareId,
    style: effectiveStyle,
    activityLabel: activityLabel,
    distanceM: distanceM,
    duration: duration,
    steps: steps,
    avgPaceLabel: averagePaceLabel(distanceM: distanceM, duration: duration),
    headline: activityShareHeadline(
      style: effectiveStyle,
      activityLabel: activityLabel,
      distanceM: distanceM,
    ),
    tagline: activityShareTagline(effectiveStyle),
    deepLink: activityShareDeepLink(shareId),
    hideStartEnd: hideStartEnd,
    includeMap: mapOn && effectiveStyle == ActivityShareStyle.map,
    hideRadiusM: hideRadiusM.clamp(200.0, 500.0),
  );
}

String formatShareElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

String formatShareSteps(int steps) {
  if (steps <= 0) return '';
  final digits = steps.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buf.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}

/// Plain-text body for OS share sheet. Deep link stub always appended.
String buildActivityShareText(ActivityShareSummary summary) {
  final lines = <String>[
    'balmi',
    summary.headline,
  ];
  final stats = <String>[formatShareElapsed(summary.duration)];
  final stepLabel = formatShareSteps(summary.steps);
  if (stepLabel.isNotEmpty) stats.add('$stepLabel걸음');
  if (summary.avgPaceLabel != null) {
    stats.add('평균 페이스 ${summary.avgPaceLabel}');
  }
  if (summary.style == ActivityShareStyle.record) {
    lines.add('${(summary.distanceM / 1000).toStringAsFixed(2)} km');
  }
  lines.add(stats.join(' · '));
  if (summary.includeMap) {
    lines.add(
      summary.hideStartEnd
          ? '경로 · 시작·종료 위치는 숨겼어요'
          : '경로 포함',
    );
  }
  lines
    ..add('')
    ..add(summary.tagline.replaceAll('\n', ' '))
    ..add('')
    ..add(summary.deepLink);
  return lines.join('\n');
}

/// Lat/lng pair without Flutter deps (share redaction + future upload).
final class ShareLatLng {
  const ShareLatLng(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Drops vertices within [radiusM] of the path start and end.
/// Protects home locations when a map/path is later shared.
List<ShareLatLng> redactSharePathStartEnd(
  List<ShareLatLng> path, {
  double radiusM = kDefaultShareHideRadiusM,
}) {
  if (path.length < 2) return const [];
  final r = radiusM.clamp(200.0, 500.0);
  final start = path.first;
  final end = path.last;

  var from = 0;
  while (from < path.length) {
    final d = haversineMeters(
      lat1: start.lat,
      lon1: start.lng,
      lat2: path[from].lat,
      lon2: path[from].lng,
    );
    if (d > r) break;
    from++;
  }

  var to = path.length - 1;
  while (to > from) {
    final d = haversineMeters(
      lat1: end.lat,
      lon1: end.lng,
      lat2: path[to].lat,
      lon2: path[to].lng,
    );
    if (d > r) break;
    to--;
  }

  if (to < from) return const [];
  return path.sublist(from, to + 1);
}

/// How much of the original path remains after redaction (0–1).
double sharePathRetentionRatio({
  required int originalCount,
  required int redactedCount,
}) {
  if (originalCount <= 0) return 0;
  return math.min(1, redactedCount / originalCount);
}
