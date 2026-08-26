import 'package:balmi/core/copy.dart';
import 'package:balmi/core/format.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/domain/engines/workout_stats.dart';
import 'package:balmi/widgets/today_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TodayHero shows label, progress bar, and goal line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: Scaffold(
          body: TodayHero(
            stats: summarizePeriod(const []),
            stepLabel: BalmiCopy.todaySteps,
            steps: 21076,
            stepGoal: 10000,
          ),
        ),
      ),
    );

    expect(find.text(BalmiCopy.todaySteps), findsOneWidget);
    expect(find.text('21076'), findsOneWidget);
    expect(
      find.text('${formatSteps(21076)} / ${formatSteps(10000)}'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
