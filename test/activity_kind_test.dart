import 'dart:io';

import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('track is a selectable activity with locked run sport', () {
    expect(ActivityKind.track.wire, 'track');
    expect(ActivityKind.track.label, '트랙');
    expect(ActivityKind.fromWire('track'), ActivityKind.track);
    expect(ActivityKind.track.isTrack, isTrue);
    expect(ActivityKind.walk.isTrack, isFalse);
    expect(ActivityKind.track.lockedSport, Sport.run);
    expect(ActivityKind.selectable, contains(ActivityKind.track));
    expect(ActivityKind.selectable.map((a) => a.label).toList(), [
      '자동',
      '걷기',
      '달리기',
      '등산',
      '트레일 러닝',
      '트랙',
    ]);
  });

  test('home uses single activity circle with long-press picker', () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    expect(home, isNot(contains('SwitchListTile')));
    expect(home, isNot(contains('_trackMode')));
    expect(home, isNot(contains('DropdownButtonFormField')));
    expect(home, isNot(contains('ActivityPills(')));
    expect(home, contains('showActivityCirclePicker'));
    expect(home, contains('onLongPress'));
    expect(home, contains('TrackSpecPills'));
    expect(home, contains('showBalmiSheet'));
    expect(home, contains('isTrack'));
    expect(home, contains('CircleAction.playSize'));
  });
}
