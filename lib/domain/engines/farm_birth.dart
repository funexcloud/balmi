import '../../core/copy.dart';
import '../models/farm/animal.dart';
import 'farm_animal.dart';
import 'farm_life.dart';

/// Korean birth / start toast for v1 water-raise herds.
String farmBirthToastForHerd(HerdKind kind) => switch (kind) {
      HerdKind.sheep => BalmiCopy.farmBirthSheep,
      HerdKind.cattle => BalmiCopy.farmBirthCow,
      HerdKind.chicken => BalmiCopy.farmBirthChickenEgg,
      HerdKind.garden => BalmiCopy.farmBirthCropSeed,
    };

/// Korean birth / start toast for v2 slot plant / adopt by animal id.
String farmBirthToastForAnimalId(String animalId) {
  final id = animalId.toLowerCase();
  if (id.contains('sheep')) return BalmiCopy.farmBirthSheep;
  if (id.contains('cow') || id.contains('cattle')) {
    return BalmiCopy.farmBirthCow;
  }
  if (id.contains('chicken')) return BalmiCopy.farmBirthChickenEgg;
  return BalmiCopy.farmV2Adopted;
}

String farmBirthToastForCrop() => BalmiCopy.farmBirthCropSeed;

String farmBirthToastForAnimal(AnimalDefinition animal) =>
    farmBirthToastForAnimalId(animal.animalId);

/// Prefer diversity across sheep / chicken / cow on empty livestock slots.
/// Order: chicken (starter egg) → sheep → cow, then fill sheep/cow again.
const kFarmLivestockAdoptOrder = [
  'animal_chicken_01',
  'animal_sheep_01',
  'animal_cow_01',
];

String pickLivestockAnimalId({
  required Iterable<String> ownedAnimalIds,
  List<String> preferOrder = kFarmLivestockAdoptOrder,
}) {
  final owned = ownedAnimalIds.toSet();
  for (final id in preferOrder) {
    if (!owned.contains(id)) return id;
  }
  // All kinds present — prefer sheep/cow livestock over another chicken.
  final livestockPrefer = preferOrder
      .where((id) => id.contains('sheep') || id.contains('cow'))
      .toList();
  if (livestockPrefer.isNotEmpty) {
    final n = owned.where((id) => livestockPrefer.contains(id)).length;
    return livestockPrefer[n % livestockPrefer.length];
  }
  return preferOrder.first;
}

/// Level-aware pick when catalog is available; else id-order fallback.
String resolveLivestockAdoptId({
  required List<AnimalDefinition> catalog,
  required Iterable<String> occupiedAnimalIds,
  required int farmLevel,
}) {
  final next = pickNextAdoptableAnimal(
    catalog: catalog,
    occupiedAnimalIds: occupiedAnimalIds,
    farmLevel: farmLevel,
  );
  if (next != null) return next.animalId;
  return pickLivestockAnimalId(ownedAnimalIds: occupiedAnimalIds);
}
