import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/map/device_traces.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/land_city.dart';
import '../../domain/engines/land_ranking.dart';
import '../../domain/engines/loop_area.dart';
import '../../domain/engines/session_land_reward.dart';
import '../../widgets/osm_trace_map.dart';

void openLandMap(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const Scaffold(
        backgroundColor: BalmiColors.paper,
        body: SafeArea(child: LandMapScreen()),
      ),
    ),
  );
}

/// 내 땅 — claimed area summary + path map + local ranking below the map.
/// No walked-path section header and no deed-guide section.
class LandMapScreen extends StatefulWidget {
  const LandMapScreen({super.key});

  @override
  State<LandMapScreen> createState() => _LandMapScreenState();
}

class _LandMapScreenState extends State<LandMapScreen> {
  DeviceTraces _traces = const DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
  var _earnedM2 = 0.0;
  var _cellCount = 0;
  List<LandRankEntry> _ranking = const [];
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<SessionRepository>();
    final traces = await loadDeviceTraces(repo);
    final sessions = await repo.closedSessions();
    var earned = 0.0;
    final cells = <String>{};
    for (final s in sessions) {
      if (!qualifiesForLand(s.totalDistM)) continue;
      final pts = await repo.pointsForSession(s.id);
      final geo = [for (final p in pts) GeoPoint(p.lat, p.lng)];
      final reward = SessionLandReward.fromSession(
        totalDistM: s.totalDistM,
        path: geo,
      );
      earned += reward.earnedM2;
      cells.addAll(pathToHexCells(geo));
    }
    if (!mounted) return;
    setState(() {
      _traces = traces;
      _earnedM2 = earned;
      _cellCount = cells.length;
      _ranking = buildLocalLandRanking(
        myEarnedM2: earned,
        myCellCount: cells.length,
        myName: BalmiCopy.landRankingMe,
      );
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: BalmiColors.ink),
              ),
              Expanded(
                child: Text(
                  BalmiCopy.landTab,
                  style: BalmiTheme.body(size: 20, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        if (_loaded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: _LandStat(
                    label: BalmiCopy.landSteppedTitle,
                    value: _earnedM2 > 0 ? formatAreaM2(_earnedM2) : '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LandStat(
                    label: BalmiCopy.sessionLandCells,
                    value: _cellCount > 0 ? '$_cellCount' : '—',
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
              child: !_loaded
                  ? const ColoredBox(
                      color: BalmiColors.mist,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : OsmTraceMap(
                      traces: _traces,
                      emptyLabel: BalmiCopy.landEmptyMine,
                      fitToPath: _traces.hasLine,
                    ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _LandRankingPanel(
            loaded: _loaded,
            entries: _ranking,
          ),
        ),
      ],
    );
  }
}

class _LandStat extends StatelessWidget {
  const _LandStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: BalmiTheme.body(size: 20, weight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// Ranking under the map — quiet label, no deed-guide chrome.
class _LandRankingPanel extends StatelessWidget {
  const _LandRankingPanel({
    required this.loaded,
    required this.entries,
  });

  final bool loaded;
  final List<LandRankEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BalmiCopy.landRanking,
            style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            BalmiCopy.landRankingLocalHint,
            style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: !loaded
                ? const SizedBox.shrink()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _LandRankRow(entry: entries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LandRankRow extends StatelessWidget {
  const _LandRankRow({required this.entry});

  final LandRankEntry entry;

  @override
  Widget build(BuildContext context) {
    final me = entry.isMe;
    final area = entry.earnedM2 > 0 ? formatAreaM2(entry.earnedM2) : '—';
    final cells =
        entry.cellCount > 0 ? '${entry.cellCount}${BalmiCopy.sessionLandCells}' : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: me
            ? BalmiColors.potato.withValues(alpha: 0.12)
            : BalmiColors.mist,
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
        border: me
            ? Border.all(color: BalmiColors.potato.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: BalmiTheme.num(
                size: 18,
                color: me ? BalmiColors.potatoDk : BalmiColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.name,
              style: BalmiTheme.body(
                size: 15,
                weight: me ? FontWeight.w800 : FontWeight.w600,
                color: me ? BalmiColors.potatoDk : BalmiColors.ink,
              ),
            ),
          ),
          Text(
            '$area · $cells',
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w700,
              color: me ? BalmiColors.potatoDk : BalmiColors.sub,
            ),
          ),
        ],
      ),
    );
  }
}
