import 'dart:io';

import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/features/onboarding/onboarding_path_visual.dart';
import 'package:balmi/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding has four story pages with key copy', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: OnboardingScreen(onDone: () => done = true),
      ),
    );
    await tester.pump();

    // MOVE
    expect(find.textContaining('걷든, 달리든'), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingMoveWalk), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingMoveRun), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingMoveTrack), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingNext), findsOneWidget);
    expect(find.byType(OnboardingPathVisual), findsWidgets);

    // No OS permission CTAs on story screens.
    expect(find.text(BalmiCopy.locationPermission), findsNothing);
    expect(find.text(BalmiCopy.alwaysLocation), findsNothing);
    expect(find.text(BalmiCopy.notificationPermission), findsNothing);
    expect(find.text(BalmiCopy.ignoreBattery), findsNothing);

    await tester.tap(find.text(BalmiCopy.onboardingNext));
    await tester.pumpAndSettle();

    // OFFLINE
    expect(find.textContaining('인터넷이 끊겨도'), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingOfflineBadge), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingGpsOk), findsOneWidget);

    await tester.tap(find.text(BalmiCopy.onboardingNext));
    await tester.pumpAndSettle();

    // RECOVERY — advance animation into restored phase
    expect(find.textContaining('앱이 종료되어도'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text(BalmiCopy.onboardingRecoveryRestored), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingRecoveryBadge), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingRecoveryBadgeEn), findsOneWidget);

    await tester.tap(find.text(BalmiCopy.onboardingNext));
    await tester.pumpAndSettle();

    // PROMISE
    expect(find.textContaining('단 한 걸음도'), findsOneWidget);
    expect(find.text(BalmiCopy.slogan), findsOneWidget);
    expect(find.text(BalmiCopy.subcopy), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingStart), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingNext), findsNothing);

    await tester.tap(find.text(BalmiCopy.onboardingStart));
    await tester.pump();
    expect(done, isTrue);
  });

  test('onboarding brand copy matches product promise', () {
    expect(BalmiCopy.slogan, '걸음은 멈춰도, 기록은 멈추지 않도록.');
    expect(BalmiCopy.subcopy, '단 한 걸음도 잃어버리지 않도록.');
    expect(BalmiCopy.onboardingPageCount, 4);
    expect(BalmiCopy.onboardingNext, '다음');
    expect(BalmiCopy.onboardingStart, 'Balmi 시작하기');
    expect(BalmiCopy.onboardingMoveTitle, contains('걷든, 달리든'));
    expect(BalmiCopy.onboardingOfflineTitle, contains('인터넷이 끊겨도'));
    expect(BalmiCopy.onboardingRecoveryTitle, contains('앱이 종료되어도'));
    expect(BalmiCopy.onboardingPromiseTitle, contains('단 한 걸음도'));
    expect(BalmiCopy.aboutTitle, '기록을 잃지 않도록 설계했습니다');
  });

  test('onboarding_screen source never imports permission packages', () {
    final src = File('lib/features/onboarding/onboarding_screen.dart')
        .readAsStringSync();
    expect(src, isNot(contains('permission_handler')));
    expect(src, isNot(contains('geolocator')));
    expect(src, isNot(contains('RecordingPermissions')));
    expect(src, isNot(contains('OemBattery')));
    expect(src, isNot(contains('naver')));
    expect(src, isNot(contains('NaverMap')));
  });

  testWidgets('path visual paints without people/shoe copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnboardingPathVisual(
            progress: 0.7,
            variant: OnboardingPathVariant.merged,
          ),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('운동화'), findsNothing);
    expect(find.textContaining('사람'), findsNothing);
  });
}
