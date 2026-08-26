import 'dart:io';

import 'package:balmi/widgets/balmi_dock.dart';
import 'package:balmi/widgets/circle_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppShell pads body and lifts snackbars by BalmiDock.extent', () {
    final shell = File('lib/features/shell/app_shell.dart').readAsStringSync();
    expect(shell, contains('BalmiDock.extent'));
    expect(shell, contains('EdgeInsets.only(bottom: dockExtent)'));
    expect(shell, contains('BalmiDock('));
    expect(shell, contains('SnackBarBehavior.floating'));
    expect(shell, contains('dockExtent + 8'));
  });

  testWidgets('AppShell-style stack keeps body CTAs above dock', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late double dockExtent;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                dockExtent = BalmiDock.extent(context);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: dockExtent),
                        child: const Align(
                          alignment: Alignment.bottomCenter,
                          child: Text('body-cta'),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BalmiDock(index: 0, onChanged: (_) {}),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(dockExtent, 100);

    final cta = tester.renderObject<RenderBox>(find.text('body-cta'));
    final ctaBottom = cta.localToGlobal(Offset(0, cta.size.height)).dy;
    expect(ctaBottom, lessThanOrEqualTo(844 - dockExtent + 0.5));
  });

  testWidgets('showBalmiSheet content clears dock; chrome covers dock band',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const sheetLabel = 'dock-clear-body';
    late double dockExtent;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 48),
            viewPadding: EdgeInsets.only(bottom: 48),
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                dockExtent = BalmiDock.extent(context);
                return Center(
                  child: TextButton(
                    onPressed: () {
                      showBalmiSheet(
                        context: context,
                        builder: (_) => const SizedBox(
                          height: 80,
                          child: Center(child: Text(sheetLabel)),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(dockExtent, 114);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final bodyBox = tester.renderObject<RenderBox>(find.text(sheetLabel));
    final bodyBottom =
        bodyBox.localToGlobal(Offset(0, bodyBox.size.height)).dy;
    expect(bodyBottom, lessThanOrEqualTo(844 - dockExtent + 0.5));

    expect(
      find.byKey(const ValueKey('balmi-sheet-dock-cover')),
      findsOneWidget,
    );
    final cover = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('balmi-sheet-dock-cover')),
    );
    final coverBottom = cover.localToGlobal(Offset(0, cover.size.height)).dy;
    // Opaque cover reaches the physical bottom (dock fully covered).
    expect(coverBottom, closeTo(844, 1.0));
    expect(cover.size.height, closeTo(dockExtent, 0.5));

    final chrome = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('balmi-sheet-chrome')),
    );
    final chromeBottom =
        chrome.localToGlobal(Offset(0, chrome.size.height)).dy;
    expect(chromeBottom, closeTo(844, 1.0));
  });
}
