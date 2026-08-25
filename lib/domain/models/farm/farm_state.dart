import 'farm_slot.dart';
import 'milestone.dart';

class UserFarmState {
  const UserFarmState({
    required this.farmLevel,
    required this.farmXp,
    required this.updatedAt,
  });

  final int farmLevel;
  final int farmXp;
  final DateTime updatedAt;
}

class UserResourceBalances {
  const UserResourceBalances({
    required this.feedBalance,
    required this.waterBalance,
    required this.nutrientBalance,
    required this.updatedAt,
  });

  final int feedBalance;
  final int waterBalance;
  final int nutrientBalance;
  final DateTime updatedAt;

  static final zero = UserResourceBalances(
    feedBalance: 0,
    waterBalance: 0,
    nutrientBalance: 0,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class ResourceTransaction {
  const ResourceTransaction({
    required this.id,
    required this.runSessionId,
    required this.feedRaw,
    required this.feedGranted,
    required this.waterGranted,
    required this.nutrientRaw,
    required this.nutrientGranted,
    required this.newTilesClaimed,
    required this.streakDaysAtTime,
    required this.createdAt,
  });

  final int id;
  final String runSessionId;
  final int feedRaw;
  final int feedGranted;
  final int waterGranted;
  final int nutrientRaw;
  final int nutrientGranted;
  final int newTilesClaimed;
  final int streakDaysAtTime;
  final DateTime createdAt;
}

class FarmSnapshot {
  const FarmSnapshot({
    required this.farm,
    required this.resources,
    required this.slots,
    required this.milestones,
    required this.badges,
  });

  final UserFarmState farm;
  final UserResourceBalances resources;
  final List<FarmSlotView> slots;
  final List<UserMilestone> milestones;
  final List<UserBadge> badges;
}
