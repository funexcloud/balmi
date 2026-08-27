import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/engines/farm_captions.dart';
import 'package:balmi/domain/engines/farm_life.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty yard: empty field then walk hint', () {
    final lines = farmHomeCaptionLines(buildings: [], herds: [], caredToday: false);
    expect(lines, contains(BalmiCopy.landEmptyField));
    expect(lines, contains(BalmiCopy.landWalkHint));
  });

  test('fence only: ready line then unlocked label', () {
    final lines = farmHomeCaptionLines(
      buildings: const [FarmKind.pastureFence],
      herds: const [],
      caredToday: false,
    );
    expect(lines.first, BalmiCopy.farmHomeReady);
    expect(lines, contains(BalmiCopy.landWalkHint));
    expect(lines, contains('울타리 목장 · ${BalmiCopy.farmUnlocked}'));
  });

  test('herds hungry vs fed', () {
    final hungry = farmHomeCaptionLines(
      buildings: const [FarmKind.pastureFence],
      herds: const [HerdKind.sheep],
      caredToday: false,
    );
    final fed = farmHomeCaptionLines(
      buildings: const [FarmKind.pastureFence],
      herds: const [HerdKind.sheep],
      caredToday: true,
    );
    expect(hungry, contains(BalmiCopy.herdsHungry));
    expect(fed, contains(BalmiCopy.herdsFed));
    expect(hungry, contains('양떼 1'));
  });

  test('contextual day-of-week, climate and region captions', () {
    final mondayMorning = farmHomeCaptionLines(
      buildings: [],
      herds: [],
      caredToday: false,
      now: DateTime(2026, 8, 24, 9, 0), // Monday 9am
      region: '서울숲',
      weather: '화창한',
    );
    expect(mondayMorning.any((l) => l.contains('월요일')), isTrue);
    expect(mondayMorning.any((l) => l.contains('화창한')), isTrue);
    expect(mondayMorning.any((l) => l.contains('서울숲')), isTrue);
  });
}
