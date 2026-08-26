import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/features/missions/missions_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Missions screen lists only non-feed presets', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SessionRepository>.value(value: repo),
        ],
        child: MaterialApp(
          theme: BalmiTheme.light(),
          home: const MissionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.missions), findsOneWidget);
    expect(find.text('오늘 30분'), findsOneWidget);
    expect(find.text('이번 주 15km'), findsOneWidget);
    expect(find.text('트랙 10바퀴'), findsOneWidget);
    expect(find.text('오늘 800m — 목장 먹이'), findsNothing);
    expect(find.textContaining('목장 먹이'), findsNothing);
    expect(find.textContaining('800m'), findsNothing);
  });
}
