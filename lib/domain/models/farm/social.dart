import 'farm_tier.dart';

class Friendship {
  const Friendship({
    required this.id,
    required this.userIdA,
    required this.userIdB,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
  });

  final int id;
  final String userIdA;
  final String userIdB;
  final FriendshipStatus status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
}

class UmatchiAction {
  const UmatchiAction({
    required this.id,
    required this.helperUserId,
    required this.recipientUserId,
    required this.resourceType,
    required this.amount,
    required this.actionDate,
    required this.createdAt,
  });

  final int id;
  final String helperUserId;
  final String recipientUserId;
  final FarmResourceType resourceType;
  final int amount;
  final String actionDate;
  final DateTime createdAt;
}

class ReactionDefinition {
  const ReactionDefinition({
    required this.reactionId,
    required this.textKr,
    required this.iconAssetKey,
  });

  final String reactionId;
  final String textKr;
  final String iconAssetKey;
}

class ReactionSent {
  const ReactionSent({
    required this.id,
    required this.senderUserId,
    required this.recipientUserId,
    required this.reactionId,
    required this.createdAt,
  });

  final int id;
  final String senderUserId;
  final String recipientUserId;
  final String reactionId;
  final DateTime createdAt;
}

/// Spec §13.2 — helper can gift once per friend per day.
bool canSendUmatchi({
  required String helperId,
  required String recipientId,
  required String todayKey,
  required Iterable<UmatchiAction> prior,
}) {
  return !prior.any(
    (a) =>
        a.helperUserId == helperId &&
        a.recipientUserId == recipientId &&
        a.actionDate == todayKey,
  );
}

/// Spec §13.2 — recipient daily cap (5 gifts/day).
bool recipientUnderDailyCap({
  required String recipientId,
  required String todayKey,
  required Iterable<UmatchiAction> prior,
  int maxPerDay = 5,
}) {
  final count = prior
      .where(
        (a) => a.recipientUserId == recipientId && a.actionDate == todayKey,
      )
      .length;
  return count < maxPerDay;
}

const umatchiHelperFxpReward = 10;
const umatchiDefaultAmount = 20;
