import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sessions, Points, Segments, Laps, SyncQueue, AppKv, Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.executor(super.e);

  AppDatabase.file(String path)
      : super(NativeDatabase(File(path), setup: _setup));

  static const fileName = 'balmi.sqlite';

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(sessions, sessions.activity);
            await m.addColumn(sessions, sessions.steps);
            await m.createTable(events);
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
