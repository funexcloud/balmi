import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/engines/workout_stats.dart';
import 'package:balmi/widgets/today_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TodayHero shows step label above the count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayHero(
            stats: summarizeEmpty,
            stepLabel: BalmiCopy.todaySteps,
            steps: 8420,
          ),
        ),
      ),
    );

    expect(find.text(BalmiCopy.todaySteps), findsOneWidget);
    expect(find.text('8420'), findsOneWidget);
  });
}
