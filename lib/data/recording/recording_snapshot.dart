class RecordingSnapshot {
  const RecordingSnapshot({
    required this.sessionId,
    required this.pointCount,
    required this.pendingChunks,
    required this.hAccM,
    required this.gpsStrength,
    required this.sport,
    required this.totalDistM,
    required this.walkDistM,
    required this.runDistM,
    required this.startedAtMs,
    required this.lapCount,
    required this.trackMode,
    this.trackSpecM,
    this.lapTts,
    this.lastLapTimeS,
    this.speedKmh,
    this.walkDurationMs = 0,
    this.runDurationMs = 0,
    this.syncedPoints = 0,
  });

  final String sessionId;
  final int pointCount;
  final int pendingChunks;
  final double? hAccM;
  final String gpsStrength;
  final String sport;
  final double totalDistM;
  final double walkDistM;
  final double runDistM;
  final int startedAtMs;
  final int lapCount;
  final bool trackMode;
  final int? trackSpecM;
  final String? lapTts;
  final double? lastLapTimeS;
  final double? speedKmh;
  final int walkDurationMs;
  final int runDurationMs;
  final int syncedPoints;

  int get pendingPoints =>
      (pointCount - syncedPoints).clamp(0, pointCount);

  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'pointCount': pointCount,
        'pendingChunks': pendingChunks,
        'hAccM': hAccM,
        'gpsStrength': gpsStrength,
        'sport': sport,
        'totalDistM': totalDistM,
        'walkDistM': walkDistM,
        'runDistM': runDistM,
        'startedAtMs': startedAtMs,
        'lapCount': lapCount,
        'trackMode': trackMode,
        'trackSpecM': trackSpecM,
        'lapTts': lapTts,
        'lastLapTimeS': lastLapTimeS,
        'speedKmh': speedKmh,
        'walkDurationMs': walkDurationMs,
        'runDurationMs': runDurationMs,
        'syncedPoints': syncedPoints,
      };

  factory RecordingSnapshot.fromJson(Map<Object?, Object?> json) {
    double? d(Object? v) {
      if (v is num) return v.toDouble();
      return null;
    }

    int i(Object? v) => v is num ? v.round() : 0;

    return RecordingSnapshot(
      sessionId: '${json['sessionId'] ?? ''}',
      pointCount: i(json['pointCount']),
      pendingChunks: i(json['pendingChunks']),
      hAccM: d(json['hAccM']),
      gpsStrength: '${json['gpsStrength'] ?? 'none'}',
      sport: '${json['sport'] ?? 'walk'}',
      totalDistM: d(json['totalDistM']) ?? 0,
      walkDistM: d(json['walkDistM']) ?? 0,
      runDistM: d(json['runDistM']) ?? 0,
      startedAtMs: i(json['startedAtMs']),
      lapCount: i(json['lapCount']),
      trackMode: json['trackMode'] == true,
      trackSpecM: json['trackSpecM'] is num ? (json['trackSpecM'] as num).round() : null,
      lapTts: json['lapTts'] as String?,
      lastLapTimeS: d(json['lastLapTimeS']),
      speedKmh: d(json['speedKmh']),
      walkDurationMs: i(json['walkDurationMs']),
      runDurationMs: i(json['runDurationMs']),
      syncedPoints: i(json['syncedPoints']),
    );
  }

  static String strengthFor(double? hAccM) {
    if (hAccM == null) return 'none';
    if (hAccM <= 10) return 'strong';
    if (hAccM <= 20) return 'ok';
    if (hAccM <= 30) return 'weak';
    return 'poor';
  }
}
