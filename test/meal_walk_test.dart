import 'package:balmi/domain/engines/meal_walk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature cannot enable without a disclaimer timestamp', () {
    expect(canEnableFeature(disclaimerAcknowledgedAt: null), isFalse);
    expect(
      canEnableFeature(disclaimerAcknowledgedAt: DateTime.utc(2026, 8, 25)),
      isTrue,
    );
  });

  test('walk prompt is 30 minutes after meal start', () {
    final meal = DateTime(2026, 8, 25, 12, 30);
    expect(walkPromptAt(meal), DateTime(2026, 8, 25, 13, 0));
  });

  test('daily reminders cap at breakfast lunch dinner', () {
    expect(
      canSendMealReminder(promptedToday: const [], meal: MealType.breakfast),
      isTrue,
    );
    expect(
      canSendMealReminder(
        promptedToday: MealType.values,
        meal: MealType.breakfast,
      ),
      isFalse,
    );
    expect(
      canSendMealReminder(
        promptedToday: const [MealType.breakfast],
        meal: MealType.breakfast,
      ),
      isFalse,
    );
    expect(
      canSendMealReminder(
        promptedToday: const [MealType.breakfast],
        meal: MealType.lunch,
      ),
      isTrue,
    );
  });

  test('15 minutes plus 50m counts as a complete walk', () {
    expect(
      meetsWalkGoal(
        elapsed: const Duration(minutes: 14, seconds: 59),
        distanceM: 80,
      ),
      isFalse,
    );
    expect(
      meetsWalkGoal(elapsed: const Duration(minutes: 15), distanceM: 49),
      isFalse,
    );
    expect(
      meetsWalkGoal(elapsed: const Duration(minutes: 15), distanceM: 50),
      isTrue,
    );
  });

  test('live recording that already meets the goal auto-completes', () {
    expect(
      shouldAutoCompleteDuringRecording(
        isRecording: true,
        sessionElapsed: const Duration(minutes: 16),
        sessionDistanceM: 120,
      ),
      isTrue,
    );
    expect(
      shouldSuppressWalkNotification(isRecording: true),
      isTrue,
    );
    expect(
      shouldSuppressWalkNotification(isRecording: false),
      isFalse,
    );
  });

  test('stopping early is partial, not a scolding status', () {
    expect(
      statusAfterWalkStop(
        elapsed: const Duration(minutes: 8),
        distanceM: 40,
      ),
      MealWalkStatus.partial,
    );
    expect(
      partialFeedback(elapsed: const Duration(minutes: 8)),
      '그래도 오늘 8분 걸으셨어요',
    );
    expect(skipCopy, '괜찮아요, 다음 끼니에 다시 해봐요');
  });

  test('adherence is completed over prompted sessions', () {
    final t0 = DateTime.utc(2026, 8, 25, 12);
    final vasa = computeMealWalkVasa([
      MealWalkSession(
        id: 'a',
        mealType: MealType.lunch,
        mealStartedAt: t0,
        walkPromptedAt: t0.add(const Duration(minutes: 30)),
        walkStartedAt: t0.add(const Duration(minutes: 32)),
        status: MealWalkStatus.completed,
      ),
      MealWalkSession(
        id: 'b',
        mealType: MealType.dinner,
        mealStartedAt: t0.add(const Duration(hours: 6)),
        walkPromptedAt: t0.add(const Duration(hours: 6, minutes: 30)),
        status: MealWalkStatus.missed,
      ),
      MealWalkSession(
        id: 'c',
        mealType: MealType.breakfast,
        mealStartedAt: t0.subtract(const Duration(hours: 4)),
        status: MealWalkStatus.pending,
      ),
    ]);
    expect(vasa.promptedSessions, 2);
    expect(vasa.completedSessions, 1);
    expect(vasa.adherenceRate, 0.5);
    expect(vasa.meanReaction, const Duration(minutes: 2));
  });

  test('meal window uses the default lunch slot', () {
    const schedule = MealSchedule.defaults;
    expect(
      mealInWindow(schedule, DateTime(2026, 8, 25, 12, 35)),
      MealType.lunch,
    );
    expect(mealInWindow(schedule, DateTime(2026, 8, 25, 15, 0), promptedToday: MealType.values), isNull);
  });

  test('defaults are 08:00, 12:30, 19:00', () {
    expect(DayMinutes.breakfastDefault.hour, 8);
    expect(DayMinutes.lunchDefault.minute, 30);
    expect(DayMinutes.dinnerDefault.hour, 19);
  });
}
