import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/copy.dart';
import 'data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  try {
    await initializeDateFormatting('ko_KR');
    final dbPath = await AppDatabase.resolveFilePath();
    final db = AppDatabase();
    runApp(BalmiApp(db: db, dbPath: dbPath));
  } catch (error) {
    runApp(LaunchErrorApp(error: error.toString()));
  }
}

class LaunchErrorApp extends StatelessWidget {
  const LaunchErrorApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: BalmiCopy.appName,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '앱을 시작하지 못했어요.\n\n$error',
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
