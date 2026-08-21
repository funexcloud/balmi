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
    this.lapTts,
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
  final String? lapTts;

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
        'lapTts': lapTts,
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
      lapTts: json['lapTts'] as String?,
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
