/// User-facing Record Survival status — no SQLite / buffer jargon.
enum RecordLink {
  online,
  offline,
  unknown,
}

enum GpsLink {
  searching,
  excellent,
  good,
  fair,
  weak,
  lost,
}

enum SyncLink {
  local,
  pending,
  syncing,
  synced,
  failed,
}

class RecordSurvivalStatus {
  const RecordSurvivalStatus({
    required this.recording,
    required this.gps,
    required this.network,
    required this.sync,
    this.paused = false,
    this.justRecovered = false,
    this.hAccM,
  });

  final bool recording;
  final bool paused;
  final bool justRecovered;
  final GpsLink gps;
  final RecordLink network;
  final SyncLink sync;
  final double? hAccM;

  /// Primary line: recording / offline / recovered.
  String get primaryLine {
    if (justRecovered) return '기록 복구 완료';
    if (!recording) return '기록 준비';
    if (paused) return '기록 일시정지';
    if (network == RecordLink.offline) return '오프라인 기록 중';
    return '기록 중';
  }

  /// Secondary trust / sync line — never mentions DB internals.
  String get saveLine {
    if (sync == SyncLink.pending || sync == SyncLink.failed) {
      return '동기화 대기';
    }
    if (sync == SyncLink.syncing) return '연결됨 · 동기화 중';
    if (sync == SyncLink.synced) return '기록 동기화 완료';
    return '기기에 안전하게 저장 중';
  }

  String get gpsLine {
    final base = switch (gps) {
      GpsLink.searching => 'GPS 찾는 중',
      GpsLink.excellent => 'GPS 우수',
      GpsLink.good => 'GPS 양호',
      GpsLink.fair => 'GPS 양호',
      GpsLink.weak => 'GPS 약함',
      GpsLink.lost => 'GPS 신호를 찾는 중',
    };
    final acc = hAccM;
    if (acc == null) return base;
    if (gps == GpsLink.searching || gps == GpsLink.lost) return base;
    return '$base · ±${acc.round()}m';
  }

  /// GPS and network are independent axes.
  bool get gpsOkWithoutNetwork =>
      network == RecordLink.offline &&
      (gps == GpsLink.excellent ||
          gps == GpsLink.good ||
          gps == GpsLink.fair);

  bool get networkOkWithoutGps =>
      network == RecordLink.online &&
      (gps == GpsLink.searching || gps == GpsLink.lost || gps == GpsLink.weak);

  static GpsLink gpsFromAccuracy(double? hAccM, {bool hasRecentFix = true}) {
    if (!hasRecentFix || hAccM == null) return GpsLink.searching;
    if (hAccM <= 5) return GpsLink.excellent;
    if (hAccM <= 10) return GpsLink.good;
    if (hAccM <= 20) return GpsLink.fair;
    if (hAccM <= 50) return GpsLink.weak;
    return GpsLink.lost;
  }

  static SyncLink syncFromQueue({
    required int pendingChunks,
    required int pendingPoints,
    bool uploading = false,
  }) {
    if (uploading) return SyncLink.syncing;
    if (pendingChunks > 0 || pendingPoints > 0) return SyncLink.pending;
    return SyncLink.local;
  }
}
