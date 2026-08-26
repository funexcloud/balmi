import 'package:balmi/widgets/locate_fixed_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LocateFixedIcon paints at requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: LocateFixedIcon(size: 24)),
        ),
      ),
    );
    final box = tester.renderObject<RenderBox>(find.byType(LocateFixedIcon));
    expect(box.size, const Size(24, 24));
  });
}
