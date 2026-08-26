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

  test('home play-only: long-press picker, track spec in sheet', () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    expect(home, isNot(contains('SwitchListTile')));
    expect(home, isNot(contains('_trackMode')));
    expect(home, isNot(contains('DropdownButtonFormField')));
    expect(home, isNot(contains('ActivityPills(')));
    expect(home, isNot(contains('ActivityPills.iconOf')));
    expect(home, contains('showActivityCirclePicker'));
    expect(home, contains('onLongPress'));
    expect(home, contains('TrackSpecPills'));
    expect(home, contains('showBalmiSheet'));
    expect(home, contains('_pickTrackSpec'));
    expect(home, contains('isTrack'));
    expect(home, contains('CircleAction.playSize'));
    expect(home, contains('Icons.play_arrow'));
    expect(home, contains('filled: true'));
    expect(home, contains('preferredActivity'));
    expect(home, contains('setPreferredActivity'));
    expect(home, contains('openFarmPreview'));
    expect(home, isNot(contains('openLandPreview')));
  });

  test('track spec sheets clear floating dock via showBalmiSheet', () {
    final sheet = File('lib/widgets/circle_action.dart').readAsStringSync();
    expect(sheet, contains('BalmiDock.extent'));
    expect(sheet, contains('dockClearance'));
    expect(sheet, contains('Colors.transparent'));
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    expect(home, contains('_pickTrackSpec'));
    expect(home, contains('TrackSpecPills'));
    expect(home, contains('showBalmiSheet'));
    final recording =
        File('lib/features/recording/recording_screen.dart').readAsStringSync();
    expect(recording, contains('showBalmiSheet'));
    expect(recording, contains('TrackSpecPills'));
  });
}
