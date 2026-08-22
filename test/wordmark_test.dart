import 'package:balmi/widgets/balmi_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wordmark exposes lowercase balmi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BalmiWordmark(height: 26)),
      ),
    );
    expect(find.byType(BalmiWordmark), findsOneWidget);
    expect(find.text('balmi'), findsWidgets);
  });
}
