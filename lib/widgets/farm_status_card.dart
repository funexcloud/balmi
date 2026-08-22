import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';

class FarmStatusCard extends StatelessWidget {
  const FarmStatusCard({
    super.key,
    required this.progressLine,
    required this.caredToday,
    required this.onOpen,
    this.buildingCount = 0,
  });

  final String progressLine;
  final bool caredToday;
  final VoidCallback onOpen;
  final int buildingCount;

  String get _line {
    if (caredToday) return BalmiCopy.herdsFed;
    if (buildingCount == 0) return BalmiCopy.farmHomeEmpty;
    return BalmiCopy.herdsHungry;
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
                      progressLine,
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
