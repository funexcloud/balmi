import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/widgets/activity_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pills include 트랙 on the same row as other activities', (tester) async {
    ActivityKind selected = ActivityKind.auto;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityPills(
            value: selected,
            onChanged: (v) => selected = v,
          ),
        ),
      ),
    );
    expect(find.text('자동'), findsOneWidget);
    expect(find.text('걷기'), findsOneWidget);
    expect(find.text('달리기'), findsOneWidget);
    expect(find.text('등산'), findsOneWidget);
    expect(find.text('트레일 러닝'), findsOneWidget);
    expect(find.text('트랙'), findsOneWidget);

    await tester.tap(find.text('트랙'));
    expect(selected, ActivityKind.track);
  });

  testWidgets('track spec uses compact pills not a dropdown', (tester) async {
    int? spec = 400;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackSpecPills(
            value: spec,
            onChanged: (v) => spec = v,
          ),
        ),
      ),
    );
    expect(find.text('400'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('자유'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int?>), findsNothing);

    await tester.tap(find.text('자유'));
    expect(spec, isNull);
  });
}
