import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/engines/farm_life.dart';
import '../domain/engines/land_city.dart';
import 'farm_scene.dart';

class FarmStatusCard extends StatelessWidget {
  const FarmStatusCard({
    super.key,
    required this.buildings,
    required this.herds,
    required this.caredToday,
    required this.onOpen,
  });

  final List<FarmKind> buildings;
  final List<HerdKind> herds;
  final bool caredToday;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BalmiColors.mist,
      borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
        onTap: onOpen,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
          // Speech-bubble taps are absorbed inside FarmScene; scene taps open land.
          child: FarmScene(
            buildings: buildings,
            herds: herds,
            caredToday: caredToday,
            height: 176,
            showSpeechCaptions: true,
          ),
        ),
      ),
    );
  }
}
