import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/engines/farm_life.dart';
import '../domain/engines/farm_scene_ui.dart';
import '../domain/engines/farm_slot_move.dart';
import '../domain/engines/land_city.dart';
import '../domain/models/farm/animal.dart';
import '../domain/models/farm/crop.dart';
import '../domain/models/farm/farm_slot.dart';
import '../domain/models/farm/farm_state.dart';
import 'farm_scene.dart';

typedef FarmSlotMoveCallback = void Function(
  FarmSlotView from,
  FarmSlotView to,
);

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
    this.onSlotMove,
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
  final FarmSlotMoveCallback? onSlotMove;

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
            ...snapshot.slots.map((slot) => _SlotAnchor(
                  slot: slot,
                  crop: slot.occupant?.cropId != null
                      ? crops[slot.occupant!.cropId!]
                      : null,
                  animal: slot.occupant?.animalId != null
                      ? animals[slot.occupant!.animalId!]
                      : null,
                  onTap: onSlotTap == null ? null : () => onSlotTap!(slot),
                  onSlotMove: onSlotMove,
                )),
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
    this.onTap,
    this.onSlotMove,
  });

  final FarmSlotView slot;
  final CropDefinition? crop;
  final AnimalDefinition? animal;
  final VoidCallback? onTap;
  final FarmSlotMoveCallback? onSlotMove;

  @override
  Widget build(BuildContext context) {
    final t = slot.template;

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
                child: _SlotChip(
                  slot: slot,
                  crop: crop,
                  animal: animal,
                  onTap: onTap,
                  onSlotMove: onSlotMove,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.crop,
    required this.animal,
    this.onTap,
    this.onSlotMove,
  });

  final FarmSlotView slot;
  final CropDefinition? crop;
  final AnimalDefinition? animal;
  final VoidCallback? onTap;
  final FarmSlotMoveCallback? onSlotMove;

  bool get _occupied =>
      slot.occupant != null && !slot.occupant!.isEmpty && slot.unlocked;

  Widget _chip({required bool highlight, double opacity = 1}) {
    final label = slotDisplayLabel(slot: slot, crop: crop, animal: animal);
    final icon = slotIcon(slot: slot, crop: crop, animal: animal);
    final empty = slot.occupant == null || slot.occupant!.isEmpty;
    final alpha = (slot.unlocked ? 1.0 : 0.35) * opacity;

    return Opacity(
      opacity: alpha,
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: BalmiColors.paper.withValues(alpha: empty ? 0.72 : 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? BalmiColors.sage
                : (empty
                    ? BalmiColors.line
                    : BalmiColors.sage.withValues(alpha: 0.5)),
            width: highlight ? 2 : 1,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final moveEnabled = onSlotMove != null && slot.unlocked;

    Widget body({required bool highlight}) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: slot.unlocked ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: _chip(highlight: highlight),
        ),
      );
    }

    if (!moveEnabled) return body(highlight: false);

    final target = DragTarget<FarmSlotView>(
      onWillAcceptWithDetails: (details) =>
          canRearrangeFarmSlots(from: details.data, to: slot),
      onAcceptWithDetails: (details) => onSlotMove!(details.data, slot),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        final child = body(highlight: highlight);
        if (!_occupied) return child;
        return LongPressDraggable<FarmSlotView>(
          data: slot,
          feedback: Material(
            color: Colors.transparent,
            elevation: 6,
            child: _chip(highlight: true),
          ),
          childWhenDragging: _chip(highlight: false, opacity: 0.35),
          child: child,
        );
      },
    );

    return target;
  }
}
