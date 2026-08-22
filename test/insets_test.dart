import 'package:balmi/core/insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gesture nav uses systemGestureInsets when padding is 0', (tester) async {
    late double inset;
    late double cta;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: 0),
          viewPadding: EdgeInsets.only(bottom: 0),
          systemGestureInsets: EdgeInsets.only(bottom: 48),
        ),
        child: Builder(
          builder: (context) {
            inset = systemNavBottomInset(context);
            cta = primaryCtaBottomPadding(context, extra: 20);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(inset, 48);
    expect(cta, 68);
  });

  testWidgets('3-button nav uses padding.bottom', (tester) async {
    late double inset;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: 48),
          viewPadding: EdgeInsets.only(bottom: 48),
          systemGestureInsets: EdgeInsets.zero,
        ),
        child: Builder(
          builder: (context) {
            inset = systemNavBottomInset(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(inset, 48);
  });
}
