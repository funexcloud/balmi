import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/format.dart';
import '../core/theme.dart';

class FarmStatusCard extends StatelessWidget {
  const FarmStatusCard({
    super.key,
    required this.buildingCount,
    required this.herdCount,
    required this.todayWalkM,
    required this.caredToday,
    required this.onOpen,
  });

  final int buildingCount;
  final int herdCount;
  final double todayWalkM;
  final bool caredToday;
  final VoidCallback onOpen;

  String get _line {
    if (buildingCount == 0) return BalmiCopy.farmHomeEmpty;
    if (herdCount == 0) return BalmiCopy.farmHomeReady;
    return caredToday ? BalmiCopy.herdsFed : BalmiCopy.herdsHungry;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BalmiColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BalmiCopy.farmOwner,
                      style: BalmiTheme.tracked(size: 10.5, color: BalmiColors.sage),
                    ),
                    const SizedBox(height: 2),
                    Text(_line, style: BalmiTheme.body(size: 14, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${BalmiCopy.todayFeed} ${formatKm(todayWalkM)}km · '
                      '${BalmiCopy.myBuildings} $buildingCount · ${BalmiCopy.myHerds} $herdCount',
                      style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BalmiColors.sub, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
