import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/widgets/activity_circle_picker.dart';
import 'package:balmi/widgets/activity_pills.dart';
import 'package:balmi/widgets/circle_action.dart';
import 'package:balmi/widgets/track_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('track activity uses TrackIcon glyph not blank stadium', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityPills.glyphOf(
            ActivityKind.track,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
    expect(find.byType(TrackIcon), findsOneWidget);
    expect(find.byIcon(Icons.stadium), findsNothing);
    expect(find.byIcon(Icons.sports), findsNothing);
  });

  testWidgets('ActivityPills track tile paints TrackIcon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityPills(
            value: ActivityKind.track,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(TrackIcon), findsOneWidget);
    expect(find.byIcon(Icons.stadium), findsNothing);
  });

  testWidgets('CircleAction glyph path shows TrackIcon for track', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CircleAction(
            glyph: ActivityPills.glyphOf(
              ActivityKind.track,
              size: 18,
              color: Colors.black,
            ),
            label: '트랙',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.byType(TrackIcon), findsOneWidget);
    expect(find.byIcon(Icons.stadium), findsNothing);
  });

  testWidgets('circle picker track wedge uses TrackIcon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showActivityCirclePicker(
                      context: context,
                      selected: ActivityKind.track,
                      origin: const Offset(200, 400),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackIcon), findsOneWidget);
    expect(find.byIcon(Icons.stadium), findsNothing);
  });
}
