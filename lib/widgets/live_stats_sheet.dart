import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/format.dart';
import '../core/theme.dart';
import 'path_spark.dart';

class LiveStatsSheet extends StatelessWidget {
  const LiveStatsSheet({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.elapsed,
    required this.distM,
    required this.speedKmh,
    required this.paused,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
    this.pauseHold = Duration.zero,
    this.altM,
    this.spark = const [],
  });

  final bool expanded;
  final VoidCallback onToggle;
  final Duration elapsed;
  final double distM;
  final double speedKmh;
  final bool paused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;
  final Duration pauseHold;
  final double? altM;
  final List<double> spark;

  double get _avgKmh {
    if (elapsed.inSeconds < 1) return 0;
    return (distM / 1000) / (elapsed.inSeconds / 3600);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BalmiColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: expanded ? '접기' : '펼치기',
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Icon(
                  expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: BalmiColors.sub,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    _cell(BalmiCopy.statTime, formatElapsed(elapsed)),
                    _divider(),
                    _cell(BalmiCopy.statDistance, distM < 1000 ? formatMeters(distM) : '${formatKm(distM)}km'),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _cell(BalmiCopy.statSpeed, formatSpeedKmh(speedKmh)),
                      _divider(),
                      _cell('평균', formatSpeedKmh(_avgKmh)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _cell(BalmiCopy.currentPace, formatPace(speedKmh)),
                      if (altM != null) ...[
                        _divider(),
                        _cell('고도', '${altM!.round()}m'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  PathSpark(values: spark),
                  if (paused) ...[
                    const SizedBox(height: 8),
                      Text(
                        formatElapsed(pauseHold),
                        style: BalmiTheme.num(size: 16),
                      ),
                  ],
                ],
                const SizedBox(height: 12),
                if (paused)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEnd,
                          child: const Text(BalmiCopy.stopShort),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: onResume,
                          child: const Text(BalmiCopy.resumeShort),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onPause,
                      child: const Text(BalmiCopy.pauseShort),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
          const SizedBox(height: 2),
          Text(value, style: BalmiTheme.num(size: 28)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: BalmiColors.line,
    );
  }
}
