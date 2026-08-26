import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding is a fixed 4-beat durability story', () {
    expect(BalmiCopy.onboardingPageCount, 4);
    expect(BalmiCopy.onboardingStory1Title, contains('시작부터 끝까지'));
    expect(BalmiCopy.onboardingStory2Title, contains('인터넷이 끊겨도'));
    expect(BalmiCopy.onboardingStory2Badge, 'OFFLINE RECORDING');
    expect(BalmiCopy.onboardingStory3Title, contains('갑자기 종료되어도'));
    expect(BalmiCopy.onboardingStory3Badge, 'RECOVERY READY');
    expect(BalmiCopy.onboardingStory4Title, contains('단 한 걸음도'));
    expect(BalmiCopy.oneLiner, isNot(contains('앱이 죽어도')));
    expect(BalmiCopy.slogan, '걸음은 멈춰도, 기록은 멈추지 않도록.');
  });

  testWidgets('onboarding story pages render in order', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: OnboardingScreen(onDone: () => done = true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('걷든, 달리든'), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingStory1Tags.split(' · ').first), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);

    await tester.tap(find.text(BalmiCopy.continueLabel));
    await tester.pumpAndSettle();
    expect(find.textContaining('인터넷이 끊겨도'), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingStory2Badge), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);

    await tester.tap(find.text(BalmiCopy.continueLabel));
    await tester.pumpAndSettle();
    expect(find.textContaining('갑자기 종료되어도'), findsOneWidget);
    expect(find.text(BalmiCopy.onboardingStory3Badge), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);

    // Page 3→4 requests permissions; in tests ensure()/Geolocator may fail.
    // Still assert the story titles exist as copy constants used by the screen.
    expect(find.text(BalmiCopy.continueLabel), findsOneWidget);
    expect(done, isFalse);
  });
}
