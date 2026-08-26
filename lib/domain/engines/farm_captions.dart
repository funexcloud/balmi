import '../../core/copy.dart';
import 'farm_life.dart';
import 'land_city.dart';

/// One-sentence farm captions for home / scene speech bubbles (tap to advance).
List<String> farmHomeCaptionLines({
  required List<FarmKind> buildings,
  required List<HerdKind> herds,
  required bool caredToday,
}) {
  if (buildings.isEmpty && herds.isEmpty) {
    return const [
      BalmiCopy.landEmptyField,
      BalmiCopy.landWalkHint,
    ];
  }

  final lines = <String>[];
  if (buildings.contains(FarmKind.pastureFence) && herds.isEmpty) {
    lines.add(BalmiCopy.farmHomeReady);
  }
  if (herds.isNotEmpty) {
    lines.add(caredToday ? BalmiCopy.herdsFed : BalmiCopy.herdsHungry);
  } else if (!lines.contains(BalmiCopy.farmHomeReady)) {
    lines.add(caredToday ? BalmiCopy.wateredToday : BalmiCopy.herdsHungry);
  } else if (caredToday) {
    lines.add(BalmiCopy.wateredToday);
  } else {
    lines.add(BalmiCopy.landWalkHint);
  }

  for (final kind in FarmKind.tiers) {
    if (buildings.contains(kind)) {
      lines.add('${kind.label} · ${BalmiCopy.farmUnlocked}');
    }
  }
  for (final kind in HerdKind.tiers) {
    final n = herds.where((h) => h == kind).length;
    if (n > 0) {
      lines.add('${kind.label} $n');
    }
  }

  return lines;
}
