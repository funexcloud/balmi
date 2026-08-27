/// Local 「내 땅」 ranking MVP — device-only, no network / crew.
///
/// Order: earned ㎡ (desc), then unique hex [cellCount] (desc).
class LandRankEntry {
  const LandRankEntry({
    required this.id,
    required this.name,
    required this.earnedM2,
    required this.cellCount,
    this.isMe = false,
    this.rank = 0,
  });

  final String id;
  final String name;
  final double earnedM2;
  final int cellCount;
  final bool isMe;

  /// 1-based place after [buildLocalLandRanking].
  final int rank;

  LandRankEntry copyWith({int? rank}) {
    return LandRankEntry(
      id: id,
      name: name,
      earnedM2: earnedM2,
      cellCount: cellCount,
      isMe: isMe,
      rank: rank ?? this.rank,
    );
  }
}

/// Fixed local neighbors so the board is readable without a server.
/// Stats are illustrative only — never synced.
const kLocalLandRankingSeeds = <LandRankEntry>[
  LandRankEntry(
    id: 'seed_park',
    name: '공원 러너',
    earnedM2: 4200,
    cellCount: 48,
  ),
  LandRankEntry(
    id: 'seed_river',
    name: '한강 아침',
    earnedM2: 2800,
    cellCount: 36,
  ),
  LandRankEntry(
    id: 'seed_block',
    name: '동네 산책',
    earnedM2: 960,
    cellCount: 14,
  ),
];

/// Builds a ranked board with the local user inserted among [seeds].
List<LandRankEntry> buildLocalLandRanking({
  required double myEarnedM2,
  required int myCellCount,
  String myName = '나',
  List<LandRankEntry> seeds = kLocalLandRankingSeeds,
}) {
  final me = LandRankEntry(
    id: 'me',
    name: myName,
    earnedM2: myEarnedM2 < 0 ? 0 : myEarnedM2,
    cellCount: myCellCount < 0 ? 0 : myCellCount,
    isMe: true,
  );
  final board = <LandRankEntry>[me, ...seeds.where((e) => !e.isMe)];
  board.sort(_compareLandRank);
  var place = 1;
  for (var i = 0; i < board.length; i++) {
    if (i > 0 && _compareLandMetrics(board[i - 1], board[i]) != 0) {
      place = i + 1;
    }
    board[i] = board[i].copyWith(rank: place);
  }
  return List.unmodifiable(board);
}

/// Sort key: area → cells → prefer me → id (stable).
int _compareLandRank(LandRankEntry a, LandRankEntry b) {
  final byMetrics = _compareLandMetrics(a, b);
  if (byMetrics != 0) return byMetrics;
  if (a.isMe != b.isMe) return a.isMe ? -1 : 1;
  return a.id.compareTo(b.id);
}

/// Competition place uses only earned ㎡ / cells.
int _compareLandMetrics(LandRankEntry a, LandRankEntry b) {
  final byArea = b.earnedM2.compareTo(a.earnedM2);
  if (byArea != 0) return byArea;
  return b.cellCount.compareTo(a.cellCount);
}
