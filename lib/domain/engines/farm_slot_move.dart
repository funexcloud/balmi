import '../models/farm/farm_slot.dart';
import '../models/farm/farm_tier.dart';

/// Whether [from]'s occupant may move/swap onto [to].
///
/// Rules: both unlocked, same slot type (crop↔crop / livestock↔livestock),
/// source occupied. Destination may be empty (move) or occupied (swap).
bool canRearrangeFarmSlots({
  required FarmSlotView from,
  required FarmSlotView to,
}) {
  if (from.template.slotId == to.template.slotId) return false;
  if (!from.unlocked || !to.unlocked) return false;
  if (from.template.slotType != to.template.slotType) return false;
  final occ = from.occupant;
  if (occ == null || occ.isEmpty) return false;
  // Occupant type must match destination template when present.
  if (occ.occupantType == OccupantType.crop &&
      to.template.slotType != SlotType.crop) {
    return false;
  }
  if (occ.occupantType == OccupantType.livestock &&
      to.template.slotType != SlotType.livestock) {
    return false;
  }
  return true;
}
