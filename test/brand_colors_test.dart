import 'dart:io';

import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Balmi Sweet Potato and Active Orange hex tokens stay locked', () {
    expect(BalmiColors.potato, const Color(0xFFD9774A));
    expect(BalmiColors.potatoDk, const Color(0xFFC45E32));
    expect(BalmiColors.activeOrange, const Color(0xFFE39A3B));
    expect(BalmiColors.amber, BalmiColors.activeOrange);
    expect(BalmiColors.trackPath, BalmiColors.potato);
    expect(BalmiColors.locationPin, BalmiColors.activeOrange);
    expect(BalmiColors.sage, const Color(0xFF7C8F6D));
    expect(BalmiColors.attention, const Color(0xFFE8C547));
    expect(BalmiColors.critical, const Color(0xFFB0442F));
  });

  test('theme primary is Sweet Potato; secondary is Active Orange', () {
    final scheme = BalmiTheme.light().colorScheme;
    expect(scheme.primary, BalmiColors.potato);
    expect(scheme.secondary, BalmiColors.activeOrange);
    expect(scheme.tertiary, BalmiColors.sage);
    expect(scheme.error, BalmiColors.critical);
  });

  test('GPS track polylines use Sweet Potato, not ink/sub', () {
    final map = File('lib/widgets/osm_trace_map.dart').readAsStringSync();
    expect(map, contains('BalmiColors.trackPath'));
    expect(map, contains('BalmiColors.trackPathMuted'));
    expect(map, contains('BalmiColors.locationPin'));
    expect(
      map.contains('color: BalmiColors.ink,\n                    strokeWidth: 4.5'),
      isFalse,
      reason: 'live GPS highlight must not be ink',
    );
    expect(
      map.contains('color: BalmiColors.sub,\n                    strokeWidth: 3'),
      isFalse,
      reason: 'historical traces must not be neutral sub gray',
    );
  });

  test('path spark uses trackPath (Sweet Potato)', () {
    final spark = File('lib/widgets/path_spark.dart').readAsStringSync();
    expect(spark, contains('BalmiColors.trackPath'));
  });

  test('docs lock brand slogans and potato path rule', () {
    final brand = File('docs/BRAND.md').readAsStringSync();
    expect(brand, contains('걸음은 멈춰도, 기록은 멈추지 않도록.'));
    expect(brand, contains('발걸음에서 혈관까지.'));
    expect(brand, contains('심장이 좋아하는 고구마색'));
    expect(brand, contains('심혈관 건강을 위한 식생활에 잘 어울리는'));
    expect(brand, contains('#D9774A'));
    expect(brand, contains('GPS track'));
    expect(brand, contains('location pin'));
    expect(brand, isNot(contains('고구마는 누구에게나 심장에 좋다')));
    expect(brand.toLowerCase(), isNot(contains('naver')));
    // Potassium caution stays in BRAND docs only (not scare copy in onboarding).
    expect(brand, contains('칼륨'));
    expect(brand, contains('문서 전용'));

    final note = File('docs/개발노트.md').readAsStringSync();
    expect(note, contains('GPS 경로'));
    expect(note, isNot(contains('고구마톤은 로고·버튼만')));
  });

  test('brand story UI copy is narrative, not absolute medical claim', () {
    expect(BalmiCopy.brandStoryHook, '심장이 좋아하는 고구마색');
    expect(
      BalmiCopy.brandStoryBody2,
      contains('심혈관 건강을 위한 식생활에 잘 어울리는'),
    );
    const blob =
        '${BalmiCopy.brandStoryWhyTitle} ${BalmiCopy.brandStoryHook} '
        '${BalmiCopy.brandStoryBody1} ${BalmiCopy.brandStoryBody2} '
        '${BalmiCopy.brandStoryBody3} ${BalmiCopy.brandStoryBridge} '
        '${BalmiCopy.brandStoryCredit}';
    expect(blob, isNot(contains('누구에게나')));
    expect(blob, isNot(contains('치료')));
    expect(blob, isNot(contains('진단')));
    expect(blob, isNot(contains('처방')));

    final onboarding =
        File('lib/features/onboarding/onboarding_screen.dart').readAsStringSync();
    expect(onboarding, isNot(contains('칼륨')));
    expect(onboarding, isNot(contains('brandStory')));
  });
}
