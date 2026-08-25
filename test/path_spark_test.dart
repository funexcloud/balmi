import 'package:balmi/widgets/path_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('sparkFromTrail uses segment lengths not a dummy slope', () {
    const a = LatLng(37.5, 127.0);
    const b = LatLng(37.501, 127.0);
    const c = LatLng(37.503, 127.0);
    final spark = sparkFromTrail([a, b, c]);
    expect(spark, hasLength(2));
    expect(spark[1], greaterThan(spark[0]));
  });

  testWidgets('PathSpark paints without labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PathSpark(values: [1, 3, 2, 5])),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('고도'), findsNothing);
    expect(find.textContaining('km'), findsNothing);
  });
}
