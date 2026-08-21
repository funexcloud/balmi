import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await initializeDateFormatting('ko_KR');
  final dbPath = await AppDatabase.resolveFilePath();
  final db = AppDatabase();
  runApp(BalmiApp(db: db, dbPath: dbPath));
}
