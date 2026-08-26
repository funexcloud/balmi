import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/map/device_traces.dart';
import '../../data/repositories/session_repository.dart';
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

/// 내 땅 — walked paths only. No farm scene, no registration guide.
class LandMapScreen extends StatefulWidget {
  const LandMapScreen({super.key});

  @override
  State<LandMapScreen> createState() => _LandMapScreenState();
}

class _LandMapScreenState extends State<LandMapScreen> {
  DeviceTraces _traces = const DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final traces = await loadDeviceTraces(context.read<SessionRepository>());
    if (!mounted) return;
    setState(() {
      _traces = traces;
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
              child: !_loaded
                  ? const ColoredBox(
                      color: BalmiColors.mist,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : OsmTraceMap(
                      traces: _traces,
                      emptyLabel: BalmiCopy.landNoPath,
                      fitToPath: _traces.hasLine,
                    ),
            ),
          ),
        ),
        if (_traces.loopAreaM2 > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${BalmiCopy.landLoopAreaHint} · ${_traces.loopAreaM2.round()}㎡',
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
            ),
          ),
      ],
    );
  }
}
