import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/engines/farm_animal.dart';
import '../domain/engines/farm_life.dart';
import '../domain/engines/farm_scene_ui.dart';
import '../domain/engines/land_city.dart';
import '../domain/models/farm/animal.dart';
import '../domain/models/farm/crop.dart';
import '../domain/models/farm/farm_slot.dart';
import '../domain/models/farm/farm_state.dart';
import 'farm_scene.dart';

/// Farm gamification v2 scene — v1 painted backdrop + anchored slot overlays.
class FarmSceneV2 extends StatelessWidget {
  const FarmSceneV2({
    super.key,
    required this.snapshot,
    required this.crops,
    required this.animals,
    required this.buildings,
    required this.herds,
    this.caredToday = false,
    this.height = 268,
    this.watering = false,
    this.onWateringComplete,
    this.onSlotTap,
  });

  final FarmSnapshot snapshot;
  final Map<String, CropDefinition> crops;
  final Map<String, AnimalDefinition> animals;
  final List<FarmKind> buildings;
  final List<HerdKind> herds;
  final bool caredToday;
  final double height;
  final bool watering;
  final VoidCallback? onWateringComplete;
  final ValueChanged<FarmSlotView>? onSlotTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FarmScene(
              buildings: buildings,
              herds: herds,
              caredToday: caredToday,
              height: height,
              watering: watering,
              onWateringComplete: onWateringComplete,
              // Land preview keeps its own status line below the scene.
              showSpeechCaptions: false,
            ),
            ...snapshot.slots.map((slot) {
              final owned = snapshot.slots
                  .map((s) => s.occupant?.animalId)
                  .whereType<String>();
              final next = pickNextAdoptableAnimal(
                catalog: animals.values.toList(),
                occupiedAnimalIds: owned,
                farmLevel: snapshot.farm.farmLevel,
              );
              return _SlotAnchor(
                slot: slot,
                crop: slot.occupant?.cropId != null
                    ? crops[slot.occupant!.cropId!]
                    : null,
                animal: slot.occupant?.animalId != null
                    ? animals[slot.occupant!.animalId!]
                    : null,
                nextAdoptable: next,
                onTap: onSlotTap == null ? null : () => onSlotTap!(slot),
              );
            }),
            Positioned(
              left: 12,
              top: 10,
              child: _LevelBadge(level: snapshot.farm.farmLevel),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BalmiColors.paper.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BalmiColors.line),
      ),
      child: Text(
        '농장 Lv.$level',
        style: BalmiTheme.body(size: 11, weight: FontWeight.w800, color: BalmiColors.ink),
      ),
    );
  }
}

class _SlotAnchor extends StatelessWidget {
  const _SlotAnchor({
    required this.slot,
    required this.crop,
    required this.animal,
    this.nextAdoptable,
    this.onTap,
  });

  final FarmSlotView slot;
  final CropDefinition? crop;
  final AnimalDefinition? animal;
  final AnimalDefinition? nextAdoptable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = slot.template;
    final label = slotDisplayLabel(
      slot: slot,
      crop: crop,
      animal: animal,
      nextAdoptable: nextAdoptable,
    );
    final icon = slotIcon(slot: slot, crop: crop, animal: animal);
    final empty = slot.occupant == null || slot.occupant!.isEmpty;
    final alpha = slot.unlocked ? 1.0 : 0.35;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final cx = w * (t.xPct / 100);
          final cy = h * (t.yPct / 100);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: cx - 28,
                top: cy - 36,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: slot.unlocked ? onTap : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Opacity(
                      opacity: alpha,
                      child: Container(
                        width: 56,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: BalmiColors.paper.withValues(alpha: empty ? 0.72 : 0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: empty ? BalmiColors.line : BalmiColors.sage.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: BalmiColors.ink.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              empty ? Icons.add : icon,
                              size: 22,
                              color: empty ? BalmiColors.sub : BalmiColors.sage,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: BalmiTheme.body(
                                size: 9,
                                weight: FontWeight.w700,
                                color: BalmiColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
