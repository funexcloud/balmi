import 'package:balmi/domain/engines/land_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ranks by earned ㎡ then cells', () {
    final board = buildLocalLandRanking(
      myEarnedM2: 1500,
      myCellCount: 20,
      seeds: const [
        LandRankEntry(id: 'a', name: 'A', earnedM2: 2000, cellCount: 10),
        LandRankEntry(id: 'b', name: 'B', earnedM2: 1500, cellCount: 30),
        LandRankEntry(id: 'c', name: 'C', earnedM2: 400, cellCount: 5),
      ],
    );

    expect(board.map((e) => e.id).toList(), ['a', 'b', 'me', 'c']);
    expect(board.map((e) => e.rank).toList(), [1, 2, 3, 4]);
    expect(board.firstWhere((e) => e.isMe).rank, 3);
  });

  test('equal area prefers higher cell count', () {
    final board = buildLocalLandRanking(
      myEarnedM2: 1000,
      myCellCount: 40,
      seeds: const [
        LandRankEntry(id: 'x', name: 'X', earnedM2: 1000, cellCount: 10),
      ],
    );
    expect(board.first.id, 'me');
    expect(board.first.rank, 1);
    expect(board.last.id, 'x');
    expect(board.last.rank, 2);
  });

  test('competition ranks share place on full metric tie', () {
    final board = buildLocalLandRanking(
      myEarnedM2: 500,
      myCellCount: 8,
      seeds: const [
        LandRankEntry(id: 't', name: 'Twin', earnedM2: 500, cellCount: 8),
        LandRankEntry(id: 'low', name: 'Low', earnedM2: 100, cellCount: 1),
      ],
    );
    expect(board[0].rank, 1);
    expect(board[1].rank, 1);
    expect(board[2].rank, 3);
    expect(board.where((e) => e.rank == 1).any((e) => e.isMe), isTrue);
  });

  test('default seeds keep a readable local board', () {
    final board = buildLocalLandRanking(myEarnedM2: 0, myCellCount: 0);
    expect(board.length, kLocalLandRankingSeeds.length + 1);
    expect(board.every((e) => e.rank >= 1), isTrue);
    expect(board.last.isMe, isTrue);
    expect(board.last.rank, board.length);
  });

  test('negative inputs clamp to zero for me', () {
    final board = buildLocalLandRanking(
      myEarnedM2: -10,
      myCellCount: -3,
      seeds: const [],
    );
    expect(board.single.earnedM2, 0);
    expect(board.single.cellCount, 0);
    expect(board.single.isMe, isTrue);
  });
}
