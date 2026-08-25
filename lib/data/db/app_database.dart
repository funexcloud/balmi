import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'farm_v2_schema.dart';
import 'meal_walk_schema.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Sessions,
    Points,
    Segments,
    Laps,
    SyncQueue,
    AppKv,
    Events,
    Buildings,
    Livestock,
    WaterEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.executor(super.e);

  AppDatabase.file(String path)
      : super(NativeDatabase(File(path), setup: _setup));

  static const fileName = 'balmi.sqlite';

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await createMealWalkTables(this);
          await createFarmV2Tables(this);
          await seedFarmV2MasterData(this);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(sessions, sessions.activity);
            await m.addColumn(sessions, sessions.steps);
            await m.createTable(events);
          }
          if (from < 3) {
            await m.createTable(buildings);
          }
          if (from < 4) {
            await m.createTable(livestock);
          }
          if (from < 5) {
            await m.createTable(waterEvents);
          }
          if (from < 6) {
            await createMealWalkTables(this);
          }
          if (from < 7) {
            await createFarmV2Tables(this);
            await seedFarmV2MasterData(this);
          }
        },
      );

  static Future<String> resolveFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, fileName);
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final file = File(await resolveFilePath());
      return NativeDatabase.createInBackground(file, setup: _setup);
    });
  }

  static void _setup(dynamic db) {
    db.execute('PRAGMA journal_mode=WAL;');
    db.execute('PRAGMA foreign_keys=ON;');
  }
}
