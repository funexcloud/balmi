import 'package:drift/drift.dart';

@DataClassName('Session')
class Sessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get status => text()();
  BoolColumn get trackMode => boolean().withDefault(const Constant(false))();
  IntColumn get trackSpecM => integer().nullable()();
  RealColumn get totalDistM => real().withDefault(const Constant(0.0))();
  RealColumn get walkDistM => real().withDefault(const Constant(0.0))();
  RealColumn get runDistM => real().withDefault(const Constant(0.0))();
  TextColumn get activity => text().withDefault(const Constant('auto'))();
  IntColumn get steps => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EventRow')
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  TextColumn get activityFilter => text().withDefault(const Constant('all'))();
  TextColumn get goalType => text()();
  RealColumn get goalValue => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('Point')
class Points extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get seq => integer()();
  DateTimeColumn get ts => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get alt => real().nullable()();
  RealColumn get speedMs => real().nullable()();
  RealColumn get hAccM => real().nullable()();
  RealColumn get cadenceSpm => real().nullable()();
  IntColumn get satCount => integer().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();
}

@DataClassName('Segment')
class Segments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get seq => integer()();
  TextColumn get sport => text()();
  TextColumn get judgedSport => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get distM => real().withDefault(const Constant(0.0))();
  IntColumn get userOverride => integer().withDefault(const Constant(0))();
}

@DataClassName('Lap')
class Laps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get lapNo => integer()();
  DateTimeColumn get crossedAt => dateTime()();
  RealColumn get lapTimeS => real()();
  RealColumn get lapDistM => real()();
}

@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  TextColumn get chunkId => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get seqFrom => integer()();
  IntColumn get seqTo => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {chunkId};
}

class AppKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
