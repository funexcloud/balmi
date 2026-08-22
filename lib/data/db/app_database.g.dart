// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackModeMeta = const VerificationMeta(
    'trackMode',
  );
  @override
  late final GeneratedColumn<bool> trackMode = GeneratedColumn<bool>(
    'track_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _trackSpecMMeta = const VerificationMeta(
    'trackSpecM',
  );
  @override
  late final GeneratedColumn<int> trackSpecM = GeneratedColumn<int>(
    'track_spec_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalDistMMeta = const VerificationMeta(
    'totalDistM',
  );
  @override
  late final GeneratedColumn<double> totalDistM = GeneratedColumn<double>(
    'total_dist_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _walkDistMMeta = const VerificationMeta(
    'walkDistM',
  );
  @override
  late final GeneratedColumn<double> walkDistM = GeneratedColumn<double>(
    'walk_dist_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _runDistMMeta = const VerificationMeta(
    'runDistM',
  );
  @override
  late final GeneratedColumn<double> runDistM = GeneratedColumn<double>(
    'run_dist_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _activityMeta = const VerificationMeta(
    'activity',
  );
  @override
  late final GeneratedColumn<String> activity = GeneratedColumn<String>(
    'activity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    status,
    trackMode,
    trackSpecM,
    totalDistM,
    walkDistM,
    runDistM,
    activity,
    steps,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('track_mode')) {
      context.handle(
        _trackModeMeta,
        trackMode.isAcceptableOrUnknown(data['track_mode']!, _trackModeMeta),
      );
    }
    if (data.containsKey('track_spec_m')) {
      context.handle(
        _trackSpecMMeta,
        trackSpecM.isAcceptableOrUnknown(
          data['track_spec_m']!,
          _trackSpecMMeta,
        ),
      );
    }
    if (data.containsKey('total_dist_m')) {
      context.handle(
        _totalDistMMeta,
        totalDistM.isAcceptableOrUnknown(
          data['total_dist_m']!,
          _totalDistMMeta,
        ),
      );
    }
    if (data.containsKey('walk_dist_m')) {
      context.handle(
        _walkDistMMeta,
        walkDistM.isAcceptableOrUnknown(data['walk_dist_m']!, _walkDistMMeta),
      );
    }
    if (data.containsKey('run_dist_m')) {
      context.handle(
        _runDistMMeta,
        runDistM.isAcceptableOrUnknown(data['run_dist_m']!, _runDistMMeta),
      );
    }
    if (data.containsKey('activity')) {
      context.handle(
        _activityMeta,
        activity.isAcceptableOrUnknown(data['activity']!, _activityMeta),
      );
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      trackMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_mode'],
      )!,
      trackSpecM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_spec_m'],
      ),
      totalDistM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_dist_m'],
      )!,
      walkDistM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}walk_dist_m'],
      )!,
      runDistM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}run_dist_m'],
      )!,
      activity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final bool trackMode;
  final int? trackSpecM;
  final double totalDistM;
  final double walkDistM;
  final double runDistM;
  final String activity;
  final int steps;
  const Session({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.trackMode,
    this.trackSpecM,
    required this.totalDistM,
    required this.walkDistM,
    required this.runDistM,
    required this.activity,
    required this.steps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['status'] = Variable<String>(status);
    map['track_mode'] = Variable<bool>(trackMode);
    if (!nullToAbsent || trackSpecM != null) {
      map['track_spec_m'] = Variable<int>(trackSpecM);
    }
    map['total_dist_m'] = Variable<double>(totalDistM);
    map['walk_dist_m'] = Variable<double>(walkDistM);
    map['run_dist_m'] = Variable<double>(runDistM);
    map['activity'] = Variable<String>(activity);
    map['steps'] = Variable<int>(steps);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      status: Value(status),
      trackMode: Value(trackMode),
      trackSpecM: trackSpecM == null && nullToAbsent
          ? const Value.absent()
          : Value(trackSpecM),
      totalDistM: Value(totalDistM),
      walkDistM: Value(walkDistM),
      runDistM: Value(runDistM),
      activity: Value(activity),
      steps: Value(steps),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      status: serializer.fromJson<String>(json['status']),
      trackMode: serializer.fromJson<bool>(json['trackMode']),
      trackSpecM: serializer.fromJson<int?>(json['trackSpecM']),
      totalDistM: serializer.fromJson<double>(json['totalDistM']),
      walkDistM: serializer.fromJson<double>(json['walkDistM']),
      runDistM: serializer.fromJson<double>(json['runDistM']),
      activity: serializer.fromJson<String>(json['activity']),
      steps: serializer.fromJson<int>(json['steps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'status': serializer.toJson<String>(status),
      'trackMode': serializer.toJson<bool>(trackMode),
      'trackSpecM': serializer.toJson<int?>(trackSpecM),
      'totalDistM': serializer.toJson<double>(totalDistM),
      'walkDistM': serializer.toJson<double>(walkDistM),
      'runDistM': serializer.toJson<double>(runDistM),
      'activity': serializer.toJson<String>(activity),
      'steps': serializer.toJson<int>(steps),
    };
  }

  Session copyWith({
    String? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? status,
    bool? trackMode,
    Value<int?> trackSpecM = const Value.absent(),
    double? totalDistM,
    double? walkDistM,
    double? runDistM,
    String? activity,
    int? steps,
  }) => Session(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    status: status ?? this.status,
    trackMode: trackMode ?? this.trackMode,
    trackSpecM: trackSpecM.present ? trackSpecM.value : this.trackSpecM,
    totalDistM: totalDistM ?? this.totalDistM,
    walkDistM: walkDistM ?? this.walkDistM,
    runDistM: runDistM ?? this.runDistM,
    activity: activity ?? this.activity,
    steps: steps ?? this.steps,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
      trackMode: data.trackMode.present ? data.trackMode.value : this.trackMode,
      trackSpecM: data.trackSpecM.present
          ? data.trackSpecM.value
          : this.trackSpecM,
      totalDistM: data.totalDistM.present
          ? data.totalDistM.value
          : this.totalDistM,
      walkDistM: data.walkDistM.present ? data.walkDistM.value : this.walkDistM,
      runDistM: data.runDistM.present ? data.runDistM.value : this.runDistM,
      activity: data.activity.present ? data.activity.value : this.activity,
      steps: data.steps.present ? data.steps.value : this.steps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('trackMode: $trackMode, ')
          ..write('trackSpecM: $trackSpecM, ')
          ..write('totalDistM: $totalDistM, ')
          ..write('walkDistM: $walkDistM, ')
          ..write('runDistM: $runDistM, ')
          ..write('activity: $activity, ')
          ..write('steps: $steps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    status,
    trackMode,
    trackSpecM,
    totalDistM,
    walkDistM,
    runDistM,
    activity,
    steps,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status &&
          other.trackMode == this.trackMode &&
          other.trackSpecM == this.trackSpecM &&
          other.totalDistM == this.totalDistM &&
          other.walkDistM == this.walkDistM &&
          other.runDistM == this.runDistM &&
          other.activity == this.activity &&
          other.steps == this.steps);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> status;
  final Value<bool> trackMode;
  final Value<int?> trackSpecM;
  final Value<double> totalDistM;
  final Value<double> walkDistM;
  final Value<double> runDistM;
  final Value<String> activity;
  final Value<int> steps;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.trackMode = const Value.absent(),
    this.trackSpecM = const Value.absent(),
    this.totalDistM = const Value.absent(),
    this.walkDistM = const Value.absent(),
    this.runDistM = const Value.absent(),
    this.activity = const Value.absent(),
    this.steps = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required String status,
    this.trackMode = const Value.absent(),
    this.trackSpecM = const Value.absent(),
    this.totalDistM = const Value.absent(),
    this.walkDistM = const Value.absent(),
    this.runDistM = const Value.absent(),
    this.activity = const Value.absent(),
    this.steps = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       status = Value(status);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? status,
    Expression<bool>? trackMode,
    Expression<int>? trackSpecM,
    Expression<double>? totalDistM,
    Expression<double>? walkDistM,
    Expression<double>? runDistM,
    Expression<String>? activity,
    Expression<int>? steps,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (trackMode != null) 'track_mode': trackMode,
      if (trackSpecM != null) 'track_spec_m': trackSpecM,
      if (totalDistM != null) 'total_dist_m': totalDistM,
      if (walkDistM != null) 'walk_dist_m': walkDistM,
      if (runDistM != null) 'run_dist_m': runDistM,
      if (activity != null) 'activity': activity,
      if (steps != null) 'steps': steps,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? status,
    Value<bool>? trackMode,
    Value<int?>? trackSpecM,
    Value<double>? totalDistM,
    Value<double>? walkDistM,
    Value<double>? runDistM,
    Value<String>? activity,
    Value<int>? steps,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      trackMode: trackMode ?? this.trackMode,
      trackSpecM: trackSpecM ?? this.trackSpecM,
      totalDistM: totalDistM ?? this.totalDistM,
      walkDistM: walkDistM ?? this.walkDistM,
      runDistM: runDistM ?? this.runDistM,
      activity: activity ?? this.activity,
      steps: steps ?? this.steps,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (trackMode.present) {
      map['track_mode'] = Variable<bool>(trackMode.value);
    }
    if (trackSpecM.present) {
      map['track_spec_m'] = Variable<int>(trackSpecM.value);
    }
    if (totalDistM.present) {
      map['total_dist_m'] = Variable<double>(totalDistM.value);
    }
    if (walkDistM.present) {
      map['walk_dist_m'] = Variable<double>(walkDistM.value);
    }
    if (runDistM.present) {
      map['run_dist_m'] = Variable<double>(runDistM.value);
    }
    if (activity.present) {
      map['activity'] = Variable<String>(activity.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('trackMode: $trackMode, ')
          ..write('trackSpecM: $trackSpecM, ')
          ..write('totalDistM: $totalDistM, ')
          ..write('walkDistM: $walkDistM, ')
          ..write('runDistM: $runDistM, ')
          ..write('activity: $activity, ')
          ..write('steps: $steps, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PointsTable extends Points with TableInfo<$PointsTable, Point> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altMeta = const VerificationMeta('alt');
  @override
  late final GeneratedColumn<double> alt = GeneratedColumn<double>(
    'alt',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMsMeta = const VerificationMeta(
    'speedMs',
  );
  @override
  late final GeneratedColumn<double> speedMs = GeneratedColumn<double>(
    'speed_ms',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hAccMMeta = const VerificationMeta('hAccM');
  @override
  late final GeneratedColumn<double> hAccM = GeneratedColumn<double>(
    'h_acc_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cadenceSpmMeta = const VerificationMeta(
    'cadenceSpm',
  );
  @override
  late final GeneratedColumn<double> cadenceSpm = GeneratedColumn<double>(
    'cadence_spm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _satCountMeta = const VerificationMeta(
    'satCount',
  );
  @override
  late final GeneratedColumn<int> satCount = GeneratedColumn<int>(
    'sat_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    ts,
    lat,
    lng,
    alt,
    speedMs,
    hAccM,
    cadenceSpm,
    satCount,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'points';
  @override
  VerificationContext validateIntegrity(
    Insertable<Point> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('alt')) {
      context.handle(
        _altMeta,
        alt.isAcceptableOrUnknown(data['alt']!, _altMeta),
      );
    }
    if (data.containsKey('speed_ms')) {
      context.handle(
        _speedMsMeta,
        speedMs.isAcceptableOrUnknown(data['speed_ms']!, _speedMsMeta),
      );
    }
    if (data.containsKey('h_acc_m')) {
      context.handle(
        _hAccMMeta,
        hAccM.isAcceptableOrUnknown(data['h_acc_m']!, _hAccMMeta),
      );
    }
    if (data.containsKey('cadence_spm')) {
      context.handle(
        _cadenceSpmMeta,
        cadenceSpm.isAcceptableOrUnknown(data['cadence_spm']!, _cadenceSpmMeta),
      );
    }
    if (data.containsKey('sat_count')) {
      context.handle(
        _satCountMeta,
        satCount.isAcceptableOrUnknown(data['sat_count']!, _satCountMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Point map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Point(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ts'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      alt: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alt'],
      ),
      speedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_ms'],
      ),
      hAccM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}h_acc_m'],
      ),
      cadenceSpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cadence_spm'],
      ),
      satCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sat_count'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PointsTable createAlias(String alias) {
    return $PointsTable(attachedDatabase, alias);
  }
}

class Point extends DataClass implements Insertable<Point> {
  final int id;
  final String sessionId;
  final int seq;
  final DateTime ts;
  final double lat;
  final double lng;
  final double? alt;
  final double? speedMs;
  final double? hAccM;
  final double? cadenceSpm;
  final int? satCount;
  final int synced;
  const Point({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.ts,
    required this.lat,
    required this.lng,
    this.alt,
    this.speedMs,
    this.hAccM,
    this.cadenceSpm,
    this.satCount,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['ts'] = Variable<DateTime>(ts);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || alt != null) {
      map['alt'] = Variable<double>(alt);
    }
    if (!nullToAbsent || speedMs != null) {
      map['speed_ms'] = Variable<double>(speedMs);
    }
    if (!nullToAbsent || hAccM != null) {
      map['h_acc_m'] = Variable<double>(hAccM);
    }
    if (!nullToAbsent || cadenceSpm != null) {
      map['cadence_spm'] = Variable<double>(cadenceSpm);
    }
    if (!nullToAbsent || satCount != null) {
      map['sat_count'] = Variable<int>(satCount);
    }
    map['synced'] = Variable<int>(synced);
    return map;
  }

  PointsCompanion toCompanion(bool nullToAbsent) {
    return PointsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      ts: Value(ts),
      lat: Value(lat),
      lng: Value(lng),
      alt: alt == null && nullToAbsent ? const Value.absent() : Value(alt),
      speedMs: speedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMs),
      hAccM: hAccM == null && nullToAbsent
          ? const Value.absent()
          : Value(hAccM),
      cadenceSpm: cadenceSpm == null && nullToAbsent
          ? const Value.absent()
          : Value(cadenceSpm),
      satCount: satCount == null && nullToAbsent
          ? const Value.absent()
          : Value(satCount),
      synced: Value(synced),
    );
  }

  factory Point.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Point(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      alt: serializer.fromJson<double?>(json['alt']),
      speedMs: serializer.fromJson<double?>(json['speedMs']),
      hAccM: serializer.fromJson<double?>(json['hAccM']),
      cadenceSpm: serializer.fromJson<double?>(json['cadenceSpm']),
      satCount: serializer.fromJson<int?>(json['satCount']),
      synced: serializer.fromJson<int>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'ts': serializer.toJson<DateTime>(ts),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'alt': serializer.toJson<double?>(alt),
      'speedMs': serializer.toJson<double?>(speedMs),
      'hAccM': serializer.toJson<double?>(hAccM),
      'cadenceSpm': serializer.toJson<double?>(cadenceSpm),
      'satCount': serializer.toJson<int?>(satCount),
      'synced': serializer.toJson<int>(synced),
    };
  }

  Point copyWith({
    int? id,
    String? sessionId,
    int? seq,
    DateTime? ts,
    double? lat,
    double? lng,
    Value<double?> alt = const Value.absent(),
    Value<double?> speedMs = const Value.absent(),
    Value<double?> hAccM = const Value.absent(),
    Value<double?> cadenceSpm = const Value.absent(),
    Value<int?> satCount = const Value.absent(),
    int? synced,
  }) => Point(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    ts: ts ?? this.ts,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    alt: alt.present ? alt.value : this.alt,
    speedMs: speedMs.present ? speedMs.value : this.speedMs,
    hAccM: hAccM.present ? hAccM.value : this.hAccM,
    cadenceSpm: cadenceSpm.present ? cadenceSpm.value : this.cadenceSpm,
    satCount: satCount.present ? satCount.value : this.satCount,
    synced: synced ?? this.synced,
  );
  Point copyWithCompanion(PointsCompanion data) {
    return Point(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      ts: data.ts.present ? data.ts.value : this.ts,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      alt: data.alt.present ? data.alt.value : this.alt,
      speedMs: data.speedMs.present ? data.speedMs.value : this.speedMs,
      hAccM: data.hAccM.present ? data.hAccM.value : this.hAccM,
      cadenceSpm: data.cadenceSpm.present
          ? data.cadenceSpm.value
          : this.cadenceSpm,
      satCount: data.satCount.present ? data.satCount.value : this.satCount,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Point(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('ts: $ts, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('alt: $alt, ')
          ..write('speedMs: $speedMs, ')
          ..write('hAccM: $hAccM, ')
          ..write('cadenceSpm: $cadenceSpm, ')
          ..write('satCount: $satCount, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    ts,
    lat,
    lng,
    alt,
    speedMs,
    hAccM,
    cadenceSpm,
    satCount,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Point &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.ts == this.ts &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.alt == this.alt &&
          other.speedMs == this.speedMs &&
          other.hAccM == this.hAccM &&
          other.cadenceSpm == this.cadenceSpm &&
          other.satCount == this.satCount &&
          other.synced == this.synced);
}

class PointsCompanion extends UpdateCompanion<Point> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<int> seq;
  final Value<DateTime> ts;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double?> alt;
  final Value<double?> speedMs;
  final Value<double?> hAccM;
  final Value<double?> cadenceSpm;
  final Value<int?> satCount;
  final Value<int> synced;
  const PointsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.ts = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.alt = const Value.absent(),
    this.speedMs = const Value.absent(),
    this.hAccM = const Value.absent(),
    this.cadenceSpm = const Value.absent(),
    this.satCount = const Value.absent(),
    this.synced = const Value.absent(),
  });
  PointsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required int seq,
    required DateTime ts,
    required double lat,
    required double lng,
    this.alt = const Value.absent(),
    this.speedMs = const Value.absent(),
    this.hAccM = const Value.absent(),
    this.cadenceSpm = const Value.absent(),
    this.satCount = const Value.absent(),
    this.synced = const Value.absent(),
  }) : sessionId = Value(sessionId),
       seq = Value(seq),
       ts = Value(ts),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<Point> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<int>? seq,
    Expression<DateTime>? ts,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? alt,
    Expression<double>? speedMs,
    Expression<double>? hAccM,
    Expression<double>? cadenceSpm,
    Expression<int>? satCount,
    Expression<int>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (ts != null) 'ts': ts,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (alt != null) 'alt': alt,
      if (speedMs != null) 'speed_ms': speedMs,
      if (hAccM != null) 'h_acc_m': hAccM,
      if (cadenceSpm != null) 'cadence_spm': cadenceSpm,
      if (satCount != null) 'sat_count': satCount,
      if (synced != null) 'synced': synced,
    });
  }

  PointsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<int>? seq,
    Value<DateTime>? ts,
    Value<double>? lat,
    Value<double>? lng,
    Value<double?>? alt,
    Value<double?>? speedMs,
    Value<double?>? hAccM,
    Value<double?>? cadenceSpm,
    Value<int?>? satCount,
    Value<int>? synced,
  }) {
    return PointsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      ts: ts ?? this.ts,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      alt: alt ?? this.alt,
      speedMs: speedMs ?? this.speedMs,
      hAccM: hAccM ?? this.hAccM,
      cadenceSpm: cadenceSpm ?? this.cadenceSpm,
      satCount: satCount ?? this.satCount,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (alt.present) {
      map['alt'] = Variable<double>(alt.value);
    }
    if (speedMs.present) {
      map['speed_ms'] = Variable<double>(speedMs.value);
    }
    if (hAccM.present) {
      map['h_acc_m'] = Variable<double>(hAccM.value);
    }
    if (cadenceSpm.present) {
      map['cadence_spm'] = Variable<double>(cadenceSpm.value);
    }
    if (satCount.present) {
      map['sat_count'] = Variable<int>(satCount.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PointsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('ts: $ts, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('alt: $alt, ')
          ..write('speedMs: $speedMs, ')
          ..write('hAccM: $hAccM, ')
          ..write('cadenceSpm: $cadenceSpm, ')
          ..write('satCount: $satCount, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $SegmentsTable extends Segments with TableInfo<$SegmentsTable, Segment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
    'sport',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _judgedSportMeta = const VerificationMeta(
    'judgedSport',
  );
  @override
  late final GeneratedColumn<String> judgedSport = GeneratedColumn<String>(
    'judged_sport',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distMMeta = const VerificationMeta('distM');
  @override
  late final GeneratedColumn<double> distM = GeneratedColumn<double>(
    'dist_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _userOverrideMeta = const VerificationMeta(
    'userOverride',
  );
  @override
  late final GeneratedColumn<int> userOverride = GeneratedColumn<int>(
    'user_override',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    sport,
    judgedSport,
    startedAt,
    endedAt,
    distM,
    userOverride,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Segment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('sport')) {
      context.handle(
        _sportMeta,
        sport.isAcceptableOrUnknown(data['sport']!, _sportMeta),
      );
    } else if (isInserting) {
      context.missing(_sportMeta);
    }
    if (data.containsKey('judged_sport')) {
      context.handle(
        _judgedSportMeta,
        judgedSport.isAcceptableOrUnknown(
          data['judged_sport']!,
          _judgedSportMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_judgedSportMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('dist_m')) {
      context.handle(
        _distMMeta,
        distM.isAcceptableOrUnknown(data['dist_m']!, _distMMeta),
      );
    }
    if (data.containsKey('user_override')) {
      context.handle(
        _userOverrideMeta,
        userOverride.isAcceptableOrUnknown(
          data['user_override']!,
          _userOverrideMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Segment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Segment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      sport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sport'],
      )!,
      judgedSport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}judged_sport'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      distM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dist_m'],
      )!,
      userOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_override'],
      )!,
    );
  }

  @override
  $SegmentsTable createAlias(String alias) {
    return $SegmentsTable(attachedDatabase, alias);
  }
}

class Segment extends DataClass implements Insertable<Segment> {
  final int id;
  final String sessionId;
  final int seq;
  final String sport;
  final String judgedSport;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distM;
  final int userOverride;
  const Segment({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.sport,
    required this.judgedSport,
    required this.startedAt,
    this.endedAt,
    required this.distM,
    required this.userOverride,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['sport'] = Variable<String>(sport);
    map['judged_sport'] = Variable<String>(judgedSport);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['dist_m'] = Variable<double>(distM);
    map['user_override'] = Variable<int>(userOverride);
    return map;
  }

  SegmentsCompanion toCompanion(bool nullToAbsent) {
    return SegmentsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      sport: Value(sport),
      judgedSport: Value(judgedSport),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      distM: Value(distM),
      userOverride: Value(userOverride),
    );
  }

  factory Segment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Segment(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      sport: serializer.fromJson<String>(json['sport']),
      judgedSport: serializer.fromJson<String>(json['judgedSport']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      distM: serializer.fromJson<double>(json['distM']),
      userOverride: serializer.fromJson<int>(json['userOverride']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'sport': serializer.toJson<String>(sport),
      'judgedSport': serializer.toJson<String>(judgedSport),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'distM': serializer.toJson<double>(distM),
      'userOverride': serializer.toJson<int>(userOverride),
    };
  }

  Segment copyWith({
    int? id,
    String? sessionId,
    int? seq,
    String? sport,
    String? judgedSport,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    double? distM,
    int? userOverride,
  }) => Segment(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    sport: sport ?? this.sport,
    judgedSport: judgedSport ?? this.judgedSport,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    distM: distM ?? this.distM,
    userOverride: userOverride ?? this.userOverride,
  );
  Segment copyWithCompanion(SegmentsCompanion data) {
    return Segment(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      sport: data.sport.present ? data.sport.value : this.sport,
      judgedSport: data.judgedSport.present
          ? data.judgedSport.value
          : this.judgedSport,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      distM: data.distM.present ? data.distM.value : this.distM,
      userOverride: data.userOverride.present
          ? data.userOverride.value
          : this.userOverride,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Segment(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('sport: $sport, ')
          ..write('judgedSport: $judgedSport, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distM: $distM, ')
          ..write('userOverride: $userOverride')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    sport,
    judgedSport,
    startedAt,
    endedAt,
    distM,
    userOverride,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Segment &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.sport == this.sport &&
          other.judgedSport == this.judgedSport &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.distM == this.distM &&
          other.userOverride == this.userOverride);
}

class SegmentsCompanion extends UpdateCompanion<Segment> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<int> seq;
  final Value<String> sport;
  final Value<String> judgedSport;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> distM;
  final Value<int> userOverride;
  const SegmentsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.sport = const Value.absent(),
    this.judgedSport = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.distM = const Value.absent(),
    this.userOverride = const Value.absent(),
  });
  SegmentsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required int seq,
    required String sport,
    required String judgedSport,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.distM = const Value.absent(),
    this.userOverride = const Value.absent(),
  }) : sessionId = Value(sessionId),
       seq = Value(seq),
       sport = Value(sport),
       judgedSport = Value(judgedSport),
       startedAt = Value(startedAt);
  static Insertable<Segment> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<int>? seq,
    Expression<String>? sport,
    Expression<String>? judgedSport,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? distM,
    Expression<int>? userOverride,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (sport != null) 'sport': sport,
      if (judgedSport != null) 'judged_sport': judgedSport,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (distM != null) 'dist_m': distM,
      if (userOverride != null) 'user_override': userOverride,
    });
  }

  SegmentsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<int>? seq,
    Value<String>? sport,
    Value<String>? judgedSport,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<double>? distM,
    Value<int>? userOverride,
  }) {
    return SegmentsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      sport: sport ?? this.sport,
      judgedSport: judgedSport ?? this.judgedSport,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distM: distM ?? this.distM,
      userOverride: userOverride ?? this.userOverride,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (judgedSport.present) {
      map['judged_sport'] = Variable<String>(judgedSport.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (distM.present) {
      map['dist_m'] = Variable<double>(distM.value);
    }
    if (userOverride.present) {
      map['user_override'] = Variable<int>(userOverride.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('sport: $sport, ')
          ..write('judgedSport: $judgedSport, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distM: $distM, ')
          ..write('userOverride: $userOverride')
          ..write(')'))
        .toString();
  }
}

class $LapsTable extends Laps with TableInfo<$LapsTable, Lap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _lapNoMeta = const VerificationMeta('lapNo');
  @override
  late final GeneratedColumn<int> lapNo = GeneratedColumn<int>(
    'lap_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _crossedAtMeta = const VerificationMeta(
    'crossedAt',
  );
  @override
  late final GeneratedColumn<DateTime> crossedAt = GeneratedColumn<DateTime>(
    'crossed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lapTimeSMeta = const VerificationMeta(
    'lapTimeS',
  );
  @override
  late final GeneratedColumn<double> lapTimeS = GeneratedColumn<double>(
    'lap_time_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lapDistMMeta = const VerificationMeta(
    'lapDistM',
  );
  @override
  late final GeneratedColumn<double> lapDistM = GeneratedColumn<double>(
    'lap_dist_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    lapNo,
    crossedAt,
    lapTimeS,
    lapDistM,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'laps';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lap> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('lap_no')) {
      context.handle(
        _lapNoMeta,
        lapNo.isAcceptableOrUnknown(data['lap_no']!, _lapNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lapNoMeta);
    }
    if (data.containsKey('crossed_at')) {
      context.handle(
        _crossedAtMeta,
        crossedAt.isAcceptableOrUnknown(data['crossed_at']!, _crossedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_crossedAtMeta);
    }
    if (data.containsKey('lap_time_s')) {
      context.handle(
        _lapTimeSMeta,
        lapTimeS.isAcceptableOrUnknown(data['lap_time_s']!, _lapTimeSMeta),
      );
    } else if (isInserting) {
      context.missing(_lapTimeSMeta);
    }
    if (data.containsKey('lap_dist_m')) {
      context.handle(
        _lapDistMMeta,
        lapDistM.isAcceptableOrUnknown(data['lap_dist_m']!, _lapDistMMeta),
      );
    } else if (isInserting) {
      context.missing(_lapDistMMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lap(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      lapNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lap_no'],
      )!,
      crossedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}crossed_at'],
      )!,
      lapTimeS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lap_time_s'],
      )!,
      lapDistM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lap_dist_m'],
      )!,
    );
  }

  @override
  $LapsTable createAlias(String alias) {
    return $LapsTable(attachedDatabase, alias);
  }
}

class Lap extends DataClass implements Insertable<Lap> {
  final int id;
  final String sessionId;
  final int lapNo;
  final DateTime crossedAt;
  final double lapTimeS;
  final double lapDistM;
  const Lap({
    required this.id,
    required this.sessionId,
    required this.lapNo,
    required this.crossedAt,
    required this.lapTimeS,
    required this.lapDistM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['lap_no'] = Variable<int>(lapNo);
    map['crossed_at'] = Variable<DateTime>(crossedAt);
    map['lap_time_s'] = Variable<double>(lapTimeS);
    map['lap_dist_m'] = Variable<double>(lapDistM);
    return map;
  }

  LapsCompanion toCompanion(bool nullToAbsent) {
    return LapsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      lapNo: Value(lapNo),
      crossedAt: Value(crossedAt),
      lapTimeS: Value(lapTimeS),
      lapDistM: Value(lapDistM),
    );
  }

  factory Lap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lap(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      lapNo: serializer.fromJson<int>(json['lapNo']),
      crossedAt: serializer.fromJson<DateTime>(json['crossedAt']),
      lapTimeS: serializer.fromJson<double>(json['lapTimeS']),
      lapDistM: serializer.fromJson<double>(json['lapDistM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'lapNo': serializer.toJson<int>(lapNo),
      'crossedAt': serializer.toJson<DateTime>(crossedAt),
      'lapTimeS': serializer.toJson<double>(lapTimeS),
      'lapDistM': serializer.toJson<double>(lapDistM),
    };
  }

  Lap copyWith({
    int? id,
    String? sessionId,
    int? lapNo,
    DateTime? crossedAt,
    double? lapTimeS,
    double? lapDistM,
  }) => Lap(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    lapNo: lapNo ?? this.lapNo,
    crossedAt: crossedAt ?? this.crossedAt,
    lapTimeS: lapTimeS ?? this.lapTimeS,
    lapDistM: lapDistM ?? this.lapDistM,
  );
  Lap copyWithCompanion(LapsCompanion data) {
    return Lap(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      lapNo: data.lapNo.present ? data.lapNo.value : this.lapNo,
      crossedAt: data.crossedAt.present ? data.crossedAt.value : this.crossedAt,
      lapTimeS: data.lapTimeS.present ? data.lapTimeS.value : this.lapTimeS,
      lapDistM: data.lapDistM.present ? data.lapDistM.value : this.lapDistM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lap(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('lapNo: $lapNo, ')
          ..write('crossedAt: $crossedAt, ')
          ..write('lapTimeS: $lapTimeS, ')
          ..write('lapDistM: $lapDistM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, lapNo, crossedAt, lapTimeS, lapDistM);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lap &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.lapNo == this.lapNo &&
          other.crossedAt == this.crossedAt &&
          other.lapTimeS == this.lapTimeS &&
          other.lapDistM == this.lapDistM);
}

class LapsCompanion extends UpdateCompanion<Lap> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<int> lapNo;
  final Value<DateTime> crossedAt;
  final Value<double> lapTimeS;
  final Value<double> lapDistM;
  const LapsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.lapNo = const Value.absent(),
    this.crossedAt = const Value.absent(),
    this.lapTimeS = const Value.absent(),
    this.lapDistM = const Value.absent(),
  });
  LapsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required int lapNo,
    required DateTime crossedAt,
    required double lapTimeS,
    required double lapDistM,
  }) : sessionId = Value(sessionId),
       lapNo = Value(lapNo),
       crossedAt = Value(crossedAt),
       lapTimeS = Value(lapTimeS),
       lapDistM = Value(lapDistM);
  static Insertable<Lap> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<int>? lapNo,
    Expression<DateTime>? crossedAt,
    Expression<double>? lapTimeS,
    Expression<double>? lapDistM,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (lapNo != null) 'lap_no': lapNo,
      if (crossedAt != null) 'crossed_at': crossedAt,
      if (lapTimeS != null) 'lap_time_s': lapTimeS,
      if (lapDistM != null) 'lap_dist_m': lapDistM,
    });
  }

  LapsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<int>? lapNo,
    Value<DateTime>? crossedAt,
    Value<double>? lapTimeS,
    Value<double>? lapDistM,
  }) {
    return LapsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      lapNo: lapNo ?? this.lapNo,
      crossedAt: crossedAt ?? this.crossedAt,
      lapTimeS: lapTimeS ?? this.lapTimeS,
      lapDistM: lapDistM ?? this.lapDistM,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (lapNo.present) {
      map['lap_no'] = Variable<int>(lapNo.value);
    }
    if (crossedAt.present) {
      map['crossed_at'] = Variable<DateTime>(crossedAt.value);
    }
    if (lapTimeS.present) {
      map['lap_time_s'] = Variable<double>(lapTimeS.value);
    }
    if (lapDistM.present) {
      map['lap_dist_m'] = Variable<double>(lapDistM.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LapsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('lapNo: $lapNo, ')
          ..write('crossedAt: $crossedAt, ')
          ..write('lapTimeS: $lapTimeS, ')
          ..write('lapDistM: $lapDistM')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chunkIdMeta = const VerificationMeta(
    'chunkId',
  );
  @override
  late final GeneratedColumn<String> chunkId = GeneratedColumn<String>(
    'chunk_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _seqFromMeta = const VerificationMeta(
    'seqFrom',
  );
  @override
  late final GeneratedColumn<int> seqFrom = GeneratedColumn<int>(
    'seq_from',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqToMeta = const VerificationMeta('seqTo');
  @override
  late final GeneratedColumn<int> seqTo = GeneratedColumn<int>(
    'seq_to',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    chunkId,
    sessionId,
    seqFrom,
    seqTo,
    retryCount,
    nextRetryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chunk_id')) {
      context.handle(
        _chunkIdMeta,
        chunkId.isAcceptableOrUnknown(data['chunk_id']!, _chunkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq_from')) {
      context.handle(
        _seqFromMeta,
        seqFrom.isAcceptableOrUnknown(data['seq_from']!, _seqFromMeta),
      );
    } else if (isInserting) {
      context.missing(_seqFromMeta);
    }
    if (data.containsKey('seq_to')) {
      context.handle(
        _seqToMeta,
        seqTo.isAcceptableOrUnknown(data['seq_to']!, _seqToMeta),
      );
    } else if (isInserting) {
      context.missing(_seqToMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextRetryAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chunkId};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      chunkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chunk_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seqFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq_from'],
      )!,
      seqTo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq_to'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String chunkId;
  final String sessionId;
  final int seqFrom;
  final int seqTo;
  final int retryCount;
  final DateTime nextRetryAt;
  const SyncQueueData({
    required this.chunkId,
    required this.sessionId,
    required this.seqFrom,
    required this.seqTo,
    required this.retryCount,
    required this.nextRetryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chunk_id'] = Variable<String>(chunkId);
    map['session_id'] = Variable<String>(sessionId);
    map['seq_from'] = Variable<int>(seqFrom);
    map['seq_to'] = Variable<int>(seqTo);
    map['retry_count'] = Variable<int>(retryCount);
    map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      chunkId: Value(chunkId),
      sessionId: Value(sessionId),
      seqFrom: Value(seqFrom),
      seqTo: Value(seqTo),
      retryCount: Value(retryCount),
      nextRetryAt: Value(nextRetryAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      chunkId: serializer.fromJson<String>(json['chunkId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seqFrom: serializer.fromJson<int>(json['seqFrom']),
      seqTo: serializer.fromJson<int>(json['seqTo']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chunkId': serializer.toJson<String>(chunkId),
      'sessionId': serializer.toJson<String>(sessionId),
      'seqFrom': serializer.toJson<int>(seqFrom),
      'seqTo': serializer.toJson<int>(seqTo),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime>(nextRetryAt),
    };
  }

  SyncQueueData copyWith({
    String? chunkId,
    String? sessionId,
    int? seqFrom,
    int? seqTo,
    int? retryCount,
    DateTime? nextRetryAt,
  }) => SyncQueueData(
    chunkId: chunkId ?? this.chunkId,
    sessionId: sessionId ?? this.sessionId,
    seqFrom: seqFrom ?? this.seqFrom,
    seqTo: seqTo ?? this.seqTo,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt ?? this.nextRetryAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      chunkId: data.chunkId.present ? data.chunkId.value : this.chunkId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seqFrom: data.seqFrom.present ? data.seqFrom.value : this.seqFrom,
      seqTo: data.seqTo.present ? data.seqTo.value : this.seqTo,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('chunkId: $chunkId, ')
          ..write('sessionId: $sessionId, ')
          ..write('seqFrom: $seqFrom, ')
          ..write('seqTo: $seqTo, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(chunkId, sessionId, seqFrom, seqTo, retryCount, nextRetryAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.chunkId == this.chunkId &&
          other.sessionId == this.sessionId &&
          other.seqFrom == this.seqFrom &&
          other.seqTo == this.seqTo &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> chunkId;
  final Value<String> sessionId;
  final Value<int> seqFrom;
  final Value<int> seqTo;
  final Value<int> retryCount;
  final Value<DateTime> nextRetryAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.chunkId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seqFrom = const Value.absent(),
    this.seqTo = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String chunkId,
    required String sessionId,
    required int seqFrom,
    required int seqTo,
    this.retryCount = const Value.absent(),
    required DateTime nextRetryAt,
    this.rowid = const Value.absent(),
  }) : chunkId = Value(chunkId),
       sessionId = Value(sessionId),
       seqFrom = Value(seqFrom),
       seqTo = Value(seqTo),
       nextRetryAt = Value(nextRetryAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? chunkId,
    Expression<String>? sessionId,
    Expression<int>? seqFrom,
    Expression<int>? seqTo,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chunkId != null) 'chunk_id': chunkId,
      if (sessionId != null) 'session_id': sessionId,
      if (seqFrom != null) 'seq_from': seqFrom,
      if (seqTo != null) 'seq_to': seqTo,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? chunkId,
    Value<String>? sessionId,
    Value<int>? seqFrom,
    Value<int>? seqTo,
    Value<int>? retryCount,
    Value<DateTime>? nextRetryAt,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      chunkId: chunkId ?? this.chunkId,
      sessionId: sessionId ?? this.sessionId,
      seqFrom: seqFrom ?? this.seqFrom,
      seqTo: seqTo ?? this.seqTo,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chunkId.present) {
      map['chunk_id'] = Variable<String>(chunkId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seqFrom.present) {
      map['seq_from'] = Variable<int>(seqFrom.value);
    }
    if (seqTo.present) {
      map['seq_to'] = Variable<int>(seqTo.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('chunkId: $chunkId, ')
          ..write('sessionId: $sessionId, ')
          ..write('seqFrom: $seqFrom, ')
          ..write('seqTo: $seqTo, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppKvTable extends AppKv with TableInfo<$AppKvTable, AppKvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppKvData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppKvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppKvData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppKvTable createAlias(String alias) {
    return $AppKvTable(attachedDatabase, alias);
  }
}

class AppKvData extends DataClass implements Insertable<AppKvData> {
  final String key;
  final String value;
  const AppKvData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppKvCompanion toCompanion(bool nullToAbsent) {
    return AppKvCompanion(key: Value(key), value: Value(value));
  }

  factory AppKvData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppKvData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppKvData copyWith({String? key, String? value}) =>
      AppKvData(key: key ?? this.key, value: value ?? this.value);
  AppKvData copyWithCompanion(AppKvCompanion data) {
    return AppKvData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppKvData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppKvData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppKvCompanion extends UpdateCompanion<AppKvData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppKvData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppKvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
    'ends_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityFilterMeta = const VerificationMeta(
    'activityFilter',
  );
  @override
  late final GeneratedColumn<String> activityFilter = GeneratedColumn<String>(
    'activity_filter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('all'),
  );
  static const VerificationMeta _goalTypeMeta = const VerificationMeta(
    'goalType',
  );
  @override
  late final GeneratedColumn<String> goalType = GeneratedColumn<String>(
    'goal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalValueMeta = const VerificationMeta(
    'goalValue',
  );
  @override
  late final GeneratedColumn<double> goalValue = GeneratedColumn<double>(
    'goal_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startsAt,
    endsAt,
    activityFilter,
    goalType,
    goalValue,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endsAtMeta);
    }
    if (data.containsKey('activity_filter')) {
      context.handle(
        _activityFilterMeta,
        activityFilter.isAcceptableOrUnknown(
          data['activity_filter']!,
          _activityFilterMeta,
        ),
      );
    }
    if (data.containsKey('goal_type')) {
      context.handle(
        _goalTypeMeta,
        goalType.isAcceptableOrUnknown(data['goal_type']!, _goalTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_goalTypeMeta);
    }
    if (data.containsKey('goal_value')) {
      context.handle(
        _goalValueMeta,
        goalValue.isAcceptableOrUnknown(data['goal_value']!, _goalValueMeta),
      );
    } else if (isInserting) {
      context.missing(_goalValueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_at'],
      )!,
      activityFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_filter'],
      )!,
      goalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_type'],
      )!,
      goalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}goal_value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final String activityFilter;
  final String goalType;
  final double goalValue;
  final DateTime createdAt;
  const EventRow({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.activityFilter,
    required this.goalType,
    required this.goalValue,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['ends_at'] = Variable<DateTime>(endsAt);
    map['activity_filter'] = Variable<String>(activityFilter);
    map['goal_type'] = Variable<String>(goalType);
    map['goal_value'] = Variable<double>(goalValue);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      name: Value(name),
      startsAt: Value(startsAt),
      endsAt: Value(endsAt),
      activityFilter: Value(activityFilter),
      goalType: Value(goalType),
      goalValue: Value(goalValue),
      createdAt: Value(createdAt),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime>(json['endsAt']),
      activityFilter: serializer.fromJson<String>(json['activityFilter']),
      goalType: serializer.fromJson<String>(json['goalType']),
      goalValue: serializer.fromJson<double>(json['goalValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'endsAt': serializer.toJson<DateTime>(endsAt),
      'activityFilter': serializer.toJson<String>(activityFilter),
      'goalType': serializer.toJson<String>(goalType),
      'goalValue': serializer.toJson<double>(goalValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EventRow copyWith({
    String? id,
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
    String? activityFilter,
    String? goalType,
    double? goalValue,
    DateTime? createdAt,
  }) => EventRow(
    id: id ?? this.id,
    name: name ?? this.name,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    activityFilter: activityFilter ?? this.activityFilter,
    goalType: goalType ?? this.goalType,
    goalValue: goalValue ?? this.goalValue,
    createdAt: createdAt ?? this.createdAt,
  );
  EventRow copyWithCompanion(EventsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      activityFilter: data.activityFilter.present
          ? data.activityFilter.value
          : this.activityFilter,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      goalValue: data.goalValue.present ? data.goalValue.value : this.goalValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('activityFilter: $activityFilter, ')
          ..write('goalType: $goalType, ')
          ..write('goalValue: $goalValue, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startsAt,
    endsAt,
    activityFilter,
    goalType,
    goalValue,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.activityFilter == this.activityFilter &&
          other.goalType == this.goalType &&
          other.goalValue == this.goalValue &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<EventRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> startsAt;
  final Value<DateTime> endsAt;
  final Value<String> activityFilter;
  final Value<String> goalType;
  final Value<double> goalValue;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.activityFilter = const Value.absent(),
    this.goalType = const Value.absent(),
    this.goalValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
    this.activityFilter = const Value.absent(),
    required String goalType,
    required double goalValue,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startsAt = Value(startsAt),
       endsAt = Value(endsAt),
       goalType = Value(goalType),
       goalValue = Value(goalValue),
       createdAt = Value(createdAt);
  static Insertable<EventRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<String>? activityFilter,
    Expression<String>? goalType,
    Expression<double>? goalValue,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (activityFilter != null) 'activity_filter': activityFilter,
      if (goalType != null) 'goal_type': goalType,
      if (goalValue != null) 'goal_value': goalValue,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? startsAt,
    Value<DateTime>? endsAt,
    Value<String>? activityFilter,
    Value<String>? goalType,
    Value<double>? goalValue,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      activityFilter: activityFilter ?? this.activityFilter,
      goalType: goalType ?? this.goalType,
      goalValue: goalValue ?? this.goalValue,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (activityFilter.present) {
      map['activity_filter'] = Variable<String>(activityFilter.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(goalType.value);
    }
    if (goalValue.present) {
      map['goal_value'] = Variable<double>(goalValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('activityFilter: $activityFilter, ')
          ..write('goalType: $goalType, ')
          ..write('goalValue: $goalValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $PointsTable points = $PointsTable(this);
  late final $SegmentsTable segments = $SegmentsTable(this);
  late final $LapsTable laps = $LapsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $AppKvTable appKv = $AppKvTable(this);
  late final $EventsTable events = $EventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    points,
    segments,
    laps,
    syncQueue,
    appKv,
    events,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  required String status,
  Value<bool> trackMode,
  Value<int?> trackSpecM,
  Value<double> totalDistM,
  Value<double> walkDistM,
  Value<double> runDistM,
  Value<String> activity,
  Value<int> steps,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<String> status,
  Value<bool> trackMode,
  Value<int?> trackSpecM,
  Value<double> totalDistM,
  Value<double> walkDistM,
  Value<double> runDistM,
  Value<String> activity,
  Value<int> steps,
  Value<int> rowid,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PointsTable, List<Point>> _pointsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.points,
    aliasName: 'sessions__id__points__session_id',
  );

  $$PointsTableProcessedTableManager get pointsRefs {
    final manager = $$PointsTableTableManager(
      $_db,
      $_db.points,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SegmentsTable, List<Segment>> _segmentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.segments,
    aliasName: 'sessions__id__segments__session_id',
  );

  $$SegmentsTableProcessedTableManager get segmentsRefs {
    final manager = $$SegmentsTableTableManager(
      $_db,
      $_db.segments,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_segmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LapsTable, List<Lap>> _lapsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.laps,
    aliasName: 'sessions__id__laps__session_id',
  );

  $$LapsTableProcessedTableManager get lapsRefs {
    final manager = $$LapsTableTableManager(
      $_db,
      $_db.laps,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lapsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncQueueTable, List<SyncQueueData>>
  _syncQueueRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncQueue,
    aliasName: 'sessions__id__sync_queue__session_id',
  );

  $$SyncQueueTableProcessedTableManager get syncQueueRefs {
    final manager = $$SyncQueueTableTableManager(
      $_db,
      $_db.syncQueue,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncQueueRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackMode => $composableBuilder(
    column: $table.trackMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackSpecM => $composableBuilder(
    column: $table.trackSpecM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistM => $composableBuilder(
    column: $table.totalDistM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get walkDistM => $composableBuilder(
    column: $table.walkDistM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get runDistM => $composableBuilder(
    column: $table.runDistM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pointsRefs(
    Expression<bool> Function($$PointsTableFilterComposer f) f,
  ) {
    final $$PointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.points,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointsTableFilterComposer(
            $db: $db,
            $table: $db.points,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> segmentsRefs(
    Expression<bool> Function($$SegmentsTableFilterComposer f) f,
  ) {
    final $$SegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableFilterComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lapsRefs(
    Expression<bool> Function($$LapsTableFilterComposer f) f,
  ) {
    final $$LapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.laps,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapsTableFilterComposer(
            $db: $db,
            $table: $db.laps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncQueueRefs(
    Expression<bool> Function($$SyncQueueTableFilterComposer f) f,
  ) {
    final $$SyncQueueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncQueue,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncQueueTableFilterComposer(
            $db: $db,
            $table: $db.syncQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackMode => $composableBuilder(
    column: $table.trackMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackSpecM => $composableBuilder(
    column: $table.trackSpecM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistM => $composableBuilder(
    column: $table.totalDistM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get walkDistM => $composableBuilder(
    column: $table.walkDistM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get runDistM => $composableBuilder(
    column: $table.runDistM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get trackMode =>
      $composableBuilder(column: $table.trackMode, builder: (column) => column);

  GeneratedColumn<int> get trackSpecM => $composableBuilder(
    column: $table.trackSpecM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDistM => $composableBuilder(
    column: $table.totalDistM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get walkDistM =>
      $composableBuilder(column: $table.walkDistM, builder: (column) => column);

  GeneratedColumn<double> get runDistM =>
      $composableBuilder(column: $table.runDistM, builder: (column) => column);

  GeneratedColumn<String> get activity =>
      $composableBuilder(column: $table.activity, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  Expression<T> pointsRefs<T extends Object>(
    Expression<T> Function($$PointsTableAnnotationComposer a) f,
  ) {
    final $$PointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.points,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointsTableAnnotationComposer(
            $db: $db,
            $table: $db.points,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> segmentsRefs<T extends Object>(
    Expression<T> Function($$SegmentsTableAnnotationComposer a) f,
  ) {
    final $$SegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lapsRefs<T extends Object>(
    Expression<T> Function($$LapsTableAnnotationComposer a) f,
  ) {
    final $$LapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.laps,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapsTableAnnotationComposer(
            $db: $db,
            $table: $db.laps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncQueueRefs<T extends Object>(
    Expression<T> Function($$SyncQueueTableAnnotationComposer a) f,
  ) {
    final $$SyncQueueTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncQueue,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncQueueTableAnnotationComposer(
            $db: $db,
            $table: $db.syncQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({
            bool pointsRefs,
            bool segmentsRefs,
            bool lapsRefs,
            bool syncQueueRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> trackMode = const Value.absent(),
                Value<int?> trackSpecM = const Value.absent(),
                Value<double> totalDistM = const Value.absent(),
                Value<double> walkDistM = const Value.absent(),
                Value<double> runDistM = const Value.absent(),
                Value<String> activity = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                trackMode: trackMode,
                trackSpecM: trackSpecM,
                totalDistM: totalDistM,
                walkDistM: walkDistM,
                runDistM: runDistM,
                activity: activity,
                steps: steps,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required String status,
                Value<bool> trackMode = const Value.absent(),
                Value<int?> trackSpecM = const Value.absent(),
                Value<double> totalDistM = const Value.absent(),
                Value<double> walkDistM = const Value.absent(),
                Value<double> runDistM = const Value.absent(),
                Value<String> activity = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                trackMode: trackMode,
                trackSpecM: trackSpecM,
                totalDistM: totalDistM,
                walkDistM: walkDistM,
                runDistM: runDistM,
                activity: activity,
                steps: steps,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                pointsRefs = false,
                segmentsRefs = false,
                lapsRefs = false,
                syncQueueRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pointsRefs) db.points,
                    if (segmentsRefs) db.segments,
                    if (lapsRefs) db.laps,
                    if (syncQueueRefs) db.syncQueue,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pointsRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          Point
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._pointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).pointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (segmentsRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          Segment
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._segmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).segmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lapsRefs)
                        await $_getPrefetchedData<Session, $SessionsTable, Lap>(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._lapsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(db, table, p0).lapsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncQueueRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          SyncQueueData
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._syncQueueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncQueueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({
        bool pointsRefs,
        bool segmentsRefs,
        bool lapsRefs,
        bool syncQueueRefs,
      })
    >;
typedef $$PointsTableCreateCompanionBuilder = PointsCompanion Function({
  Value<int> id,
  required String sessionId,
  required int seq,
  required DateTime ts,
  required double lat,
  required double lng,
  Value<double?> alt,
  Value<double?> speedMs,
  Value<double?> hAccM,
  Value<double?> cadenceSpm,
  Value<int?> satCount,
  Value<int> synced,
});
typedef $$PointsTableUpdateCompanionBuilder = PointsCompanion Function({
  Value<int> id,
  Value<String> sessionId,
  Value<int> seq,
  Value<DateTime> ts,
  Value<double> lat,
  Value<double> lng,
  Value<double?> alt,
  Value<double?> speedMs,
  Value<double?> hAccM,
  Value<double?> cadenceSpm,
  Value<int?> satCount,
  Value<int> synced,
});

final class $$PointsTableReferences
    extends BaseReferences<_$AppDatabase, $PointsTable, Point> {
  $$PointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('points__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PointsTableFilterComposer
    extends Composer<_$AppDatabase, $PointsTable> {
  $$PointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alt => $composableBuilder(
    column: $table.alt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMs => $composableBuilder(
    column: $table.speedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hAccM => $composableBuilder(
    column: $table.hAccM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cadenceSpm => $composableBuilder(
    column: $table.cadenceSpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get satCount => $composableBuilder(
    column: $table.satCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PointsTableOrderingComposer
    extends Composer<_$AppDatabase, $PointsTable> {
  $$PointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alt => $composableBuilder(
    column: $table.alt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMs => $composableBuilder(
    column: $table.speedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hAccM => $composableBuilder(
    column: $table.hAccM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cadenceSpm => $composableBuilder(
    column: $table.cadenceSpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get satCount => $composableBuilder(
    column: $table.satCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PointsTable> {
  $$PointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get alt =>
      $composableBuilder(column: $table.alt, builder: (column) => column);

  GeneratedColumn<double> get speedMs =>
      $composableBuilder(column: $table.speedMs, builder: (column) => column);

  GeneratedColumn<double> get hAccM =>
      $composableBuilder(column: $table.hAccM, builder: (column) => column);

  GeneratedColumn<double> get cadenceSpm => $composableBuilder(
    column: $table.cadenceSpm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get satCount =>
      $composableBuilder(column: $table.satCount, builder: (column) => column);

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PointsTable,
          Point,
          $$PointsTableFilterComposer,
          $$PointsTableOrderingComposer,
          $$PointsTableAnnotationComposer,
          $$PointsTableCreateCompanionBuilder,
          $$PointsTableUpdateCompanionBuilder,
          (Point, $$PointsTableReferences),
          Point,
          PrefetchHooks Function({bool sessionId})
        > {
  $$PointsTableTableManager(_$AppDatabase db, $PointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<DateTime> ts = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double?> alt = const Value.absent(),
                Value<double?> speedMs = const Value.absent(),
                Value<double?> hAccM = const Value.absent(),
                Value<double?> cadenceSpm = const Value.absent(),
                Value<int?> satCount = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => PointsCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                ts: ts,
                lat: lat,
                lng: lng,
                alt: alt,
                speedMs: speedMs,
                hAccM: hAccM,
                cadenceSpm: cadenceSpm,
                satCount: satCount,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required int seq,
                required DateTime ts,
                required double lat,
                required double lng,
                Value<double?> alt = const Value.absent(),
                Value<double?> speedMs = const Value.absent(),
                Value<double?> hAccM = const Value.absent(),
                Value<double?> cadenceSpm = const Value.absent(),
                Value<int?> satCount = const Value.absent(),
                Value<int> synced = const Value.absent(),
              }) => PointsCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                ts: ts,
                lat: lat,
                lng: lng,
                alt: alt,
                speedMs: speedMs,
                hAccM: hAccM,
                cadenceSpm: cadenceSpm,
                satCount: satCount,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PointsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$PointsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$PointsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PointsTable,
      Point,
      $$PointsTableFilterComposer,
      $$PointsTableOrderingComposer,
      $$PointsTableAnnotationComposer,
      $$PointsTableCreateCompanionBuilder,
      $$PointsTableUpdateCompanionBuilder,
      (Point, $$PointsTableReferences),
      Point,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$SegmentsTableCreateCompanionBuilder = SegmentsCompanion Function({
  Value<int> id,
  required String sessionId,
  required int seq,
  required String sport,
  required String judgedSport,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<double> distM,
  Value<int> userOverride,
});
typedef $$SegmentsTableUpdateCompanionBuilder = SegmentsCompanion Function({
  Value<int> id,
  Value<String> sessionId,
  Value<int> seq,
  Value<String> sport,
  Value<String> judgedSport,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<double> distM,
  Value<int> userOverride,
});

final class $$SegmentsTableReferences
    extends BaseReferences<_$AppDatabase, $SegmentsTable, Segment> {
  $$SegmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('segments__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get judgedSport => $composableBuilder(
    column: $table.judgedSport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distM => $composableBuilder(
    column: $table.distM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userOverride => $composableBuilder(
    column: $table.userOverride,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get judgedSport => $composableBuilder(
    column: $table.judgedSport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distM => $composableBuilder(
    column: $table.distM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userOverride => $composableBuilder(
    column: $table.userOverride,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<String> get judgedSport => $composableBuilder(
    column: $table.judgedSport,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get distM =>
      $composableBuilder(column: $table.distM, builder: (column) => column);

  GeneratedColumn<int> get userOverride => $composableBuilder(
    column: $table.userOverride,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SegmentsTable,
          Segment,
          $$SegmentsTableFilterComposer,
          $$SegmentsTableOrderingComposer,
          $$SegmentsTableAnnotationComposer,
          $$SegmentsTableCreateCompanionBuilder,
          $$SegmentsTableUpdateCompanionBuilder,
          (Segment, $$SegmentsTableReferences),
          Segment,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SegmentsTableTableManager(_$AppDatabase db, $SegmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> sport = const Value.absent(),
                Value<String> judgedSport = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> distM = const Value.absent(),
                Value<int> userOverride = const Value.absent(),
              }) => SegmentsCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                sport: sport,
                judgedSport: judgedSport,
                startedAt: startedAt,
                endedAt: endedAt,
                distM: distM,
                userOverride: userOverride,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required int seq,
                required String sport,
                required String judgedSport,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> distM = const Value.absent(),
                Value<int> userOverride = const Value.absent(),
              }) => SegmentsCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                sport: sport,
                judgedSport: judgedSport,
                startedAt: startedAt,
                endedAt: endedAt,
                distM: distM,
                userOverride: userOverride,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SegmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SegmentsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$SegmentsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SegmentsTable,
      Segment,
      $$SegmentsTableFilterComposer,
      $$SegmentsTableOrderingComposer,
      $$SegmentsTableAnnotationComposer,
      $$SegmentsTableCreateCompanionBuilder,
      $$SegmentsTableUpdateCompanionBuilder,
      (Segment, $$SegmentsTableReferences),
      Segment,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$LapsTableCreateCompanionBuilder = LapsCompanion Function({
  Value<int> id,
  required String sessionId,
  required int lapNo,
  required DateTime crossedAt,
  required double lapTimeS,
  required double lapDistM,
});
typedef $$LapsTableUpdateCompanionBuilder = LapsCompanion Function({
  Value<int> id,
  Value<String> sessionId,
  Value<int> lapNo,
  Value<DateTime> crossedAt,
  Value<double> lapTimeS,
  Value<double> lapDistM,
});

final class $$LapsTableReferences
    extends BaseReferences<_$AppDatabase, $LapsTable, Lap> {
  $$LapsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('laps__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LapsTableFilterComposer extends Composer<_$AppDatabase, $LapsTable> {
  $$LapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapNo => $composableBuilder(
    column: $table.lapNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get crossedAt => $composableBuilder(
    column: $table.crossedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lapTimeS => $composableBuilder(
    column: $table.lapTimeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lapDistM => $composableBuilder(
    column: $table.lapDistM,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableOrderingComposer extends Composer<_$AppDatabase, $LapsTable> {
  $$LapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapNo => $composableBuilder(
    column: $table.lapNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get crossedAt => $composableBuilder(
    column: $table.crossedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lapTimeS => $composableBuilder(
    column: $table.lapTimeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lapDistM => $composableBuilder(
    column: $table.lapDistM,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LapsTable> {
  $$LapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lapNo =>
      $composableBuilder(column: $table.lapNo, builder: (column) => column);

  GeneratedColumn<DateTime> get crossedAt =>
      $composableBuilder(column: $table.crossedAt, builder: (column) => column);

  GeneratedColumn<double> get lapTimeS =>
      $composableBuilder(column: $table.lapTimeS, builder: (column) => column);

  GeneratedColumn<double> get lapDistM =>
      $composableBuilder(column: $table.lapDistM, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LapsTable,
          Lap,
          $$LapsTableFilterComposer,
          $$LapsTableOrderingComposer,
          $$LapsTableAnnotationComposer,
          $$LapsTableCreateCompanionBuilder,
          $$LapsTableUpdateCompanionBuilder,
          (Lap, $$LapsTableReferences),
          Lap,
          PrefetchHooks Function({bool sessionId})
        > {
  $$LapsTableTableManager(_$AppDatabase db, $LapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> lapNo = const Value.absent(),
                Value<DateTime> crossedAt = const Value.absent(),
                Value<double> lapTimeS = const Value.absent(),
                Value<double> lapDistM = const Value.absent(),
              }) => LapsCompanion(
                id: id,
                sessionId: sessionId,
                lapNo: lapNo,
                crossedAt: crossedAt,
                lapTimeS: lapTimeS,
                lapDistM: lapDistM,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required int lapNo,
                required DateTime crossedAt,
                required double lapTimeS,
                required double lapDistM,
              }) => LapsCompanion.insert(
                id: id,
                sessionId: sessionId,
                lapNo: lapNo,
                crossedAt: crossedAt,
                lapTimeS: lapTimeS,
                lapDistM: lapDistM,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$LapsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$LapsTableReferences._sessionIdTable(
                          db,
                        ),
                        referencedColumn: $$LapsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LapsTable,
      Lap,
      $$LapsTableFilterComposer,
      $$LapsTableOrderingComposer,
      $$LapsTableAnnotationComposer,
      $$LapsTableCreateCompanionBuilder,
      $$LapsTableUpdateCompanionBuilder,
      (Lap, $$LapsTableReferences),
      Lap,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String chunkId,
  required String sessionId,
  required int seqFrom,
  required int seqTo,
  Value<int> retryCount,
  required DateTime nextRetryAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> chunkId,
  Value<String> sessionId,
  Value<int> seqFrom,
  Value<int> seqTo,
  Value<int> retryCount,
  Value<DateTime> nextRetryAt,
  Value<int> rowid,
});

final class $$SyncQueueTableReferences
    extends BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData> {
  $$SyncQueueTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('sync_queue__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chunkId => $composableBuilder(
    column: $table.chunkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seqFrom => $composableBuilder(
    column: $table.seqFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seqTo => $composableBuilder(
    column: $table.seqTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chunkId => $composableBuilder(
    column: $table.chunkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seqFrom => $composableBuilder(
    column: $table.seqFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seqTo => $composableBuilder(
    column: $table.seqTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chunkId =>
      $composableBuilder(column: $table.chunkId, builder: (column) => column);

  GeneratedColumn<int> get seqFrom =>
      $composableBuilder(column: $table.seqFrom, builder: (column) => column);

  GeneratedColumn<int> get seqTo =>
      $composableBuilder(column: $table.seqTo, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (SyncQueueData, $$SyncQueueTableReferences),
          SyncQueueData,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chunkId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> seqFrom = const Value.absent(),
                Value<int> seqTo = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> nextRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                chunkId: chunkId,
                sessionId: sessionId,
                seqFrom: seqFrom,
                seqTo: seqTo,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chunkId,
                required String sessionId,
                required int seqFrom,
                required int seqTo,
                Value<int> retryCount = const Value.absent(),
                required DateTime nextRetryAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                chunkId: chunkId,
                sessionId: sessionId,
                seqFrom: seqFrom,
                seqTo: seqTo,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncQueueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SyncQueueTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$SyncQueueTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (SyncQueueData, $$SyncQueueTableReferences),
      SyncQueueData,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$AppKvTableCreateCompanionBuilder = AppKvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppKvTableUpdateCompanionBuilder = AppKvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppKvTableFilterComposer extends Composer<_$AppDatabase, $AppKvTable> {
  $$AppKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppKvTableOrderingComposer
    extends Composer<_$AppDatabase, $AppKvTable> {
  $$AppKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppKvTable> {
  $$AppKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppKvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppKvTable,
          AppKvData,
          $$AppKvTableFilterComposer,
          $$AppKvTableOrderingComposer,
          $$AppKvTableAnnotationComposer,
          $$AppKvTableCreateCompanionBuilder,
          $$AppKvTableUpdateCompanionBuilder,
          (AppKvData, BaseReferences<_$AppDatabase, $AppKvTable, AppKvData>),
          AppKvData,
          PrefetchHooks Function()
        > {
  $$AppKvTableTableManager(_$AppDatabase db, $AppKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppKvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppKvCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppKvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppKvTable,
      AppKvData,
      $$AppKvTableFilterComposer,
      $$AppKvTableOrderingComposer,
      $$AppKvTableAnnotationComposer,
      $$AppKvTableCreateCompanionBuilder,
      $$AppKvTableUpdateCompanionBuilder,
      (AppKvData, BaseReferences<_$AppDatabase, $AppKvTable, AppKvData>),
      AppKvData,
      PrefetchHooks Function()
    >;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  required String id,
  required String name,
  required DateTime startsAt,
  required DateTime endsAt,
  Value<String> activityFilter,
  required String goalType,
  required double goalValue,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> startsAt,
  Value<DateTime> endsAt,
  Value<String> activityFilter,
  Value<String> goalType,
  Value<double> goalValue,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityFilter => $composableBuilder(
    column: $table.activityFilter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get goalValue => $composableBuilder(
    column: $table.goalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityFilter => $composableBuilder(
    column: $table.activityFilter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get goalValue => $composableBuilder(
    column: $table.goalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<String> get activityFilter => $composableBuilder(
    column: $table.activityFilter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get goalType =>
      $composableBuilder(column: $table.goalType, builder: (column) => column);

  GeneratedColumn<double> get goalValue =>
      $composableBuilder(column: $table.goalValue, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          EventRow,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (EventRow, BaseReferences<_$AppDatabase, $EventsTable, EventRow>),
          EventRow,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<DateTime> endsAt = const Value.absent(),
                Value<String> activityFilter = const Value.absent(),
                Value<String> goalType = const Value.absent(),
                Value<double> goalValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                name: name,
                startsAt: startsAt,
                endsAt: endsAt,
                activityFilter: activityFilter,
                goalType: goalType,
                goalValue: goalValue,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime startsAt,
                required DateTime endsAt,
                Value<String> activityFilter = const Value.absent(),
                required String goalType,
                required double goalValue,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                name: name,
                startsAt: startsAt,
                endsAt: endsAt,
                activityFilter: activityFilter,
                goalType: goalType,
                goalValue: goalValue,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      EventRow,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$AppDatabase, $EventsTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$PointsTableTableManager get points =>
      $$PointsTableTableManager(_db, _db.points);
  $$SegmentsTableTableManager get segments =>
      $$SegmentsTableTableManager(_db, _db.segments);
  $$LapsTableTableManager get laps => $$LapsTableTableManager(_db, _db.laps);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$AppKvTableTableManager get appKv =>
      $$AppKvTableTableManager(_db, _db.appKv);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
}
