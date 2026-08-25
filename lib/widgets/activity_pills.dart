import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../domain/models/activity.dart';

/// Two equal rows of activity icons (not labeled chrome pills).
class ActivityPills extends StatelessWidget {
  const ActivityPills({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ActivityKind value;
  final ValueChanged<ActivityKind> onChanged;

  static const _row1 = [
    ActivityKind.auto,
    ActivityKind.walk,
    ActivityKind.run,
  ];
  static const _row2 = [
    ActivityKind.hike,
    ActivityKind.trail,
    ActivityKind.track,
  ];

  static IconData iconOf(ActivityKind a) => switch (a) {
        ActivityKind.auto => Icons.auto_mode,
        ActivityKind.walk => Icons.directions_walk,
        ActivityKind.run => Icons.directions_run,
        ActivityKind.hike => Icons.terrain,
        ActivityKind.trail => Icons.hiking,
        ActivityKind.track => Icons.stadium,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(_row1),
        const SizedBox(height: 6),
        _row(_row2),
      ],
    );
  }

  Widget _row(List<ActivityKind> kinds) {
    return Row(
      children: [
        for (var i = 0; i < kinds.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _tile(kinds[i])),
        ],
      ],
    );
  }

  Widget _tile(ActivityKind a) {
    final on = value == a;
    return Semantics(
      button: true,
      selected: on,
      label: a.label,
      child: Material(
        color: on ? BalmiColors.potato : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onChanged(a),
          child: SizedBox(
            height: 48,
            child: Icon(
              iconOf(a),
              size: 22,
              color: on ? Colors.white : BalmiColors.sub,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact spec chips under 트랙 — 400 / 300 / 200 / 자유.
class TrackSpecPills extends StatelessWidget {
  const TrackSpecPills({
    super.key,
    required this.value,
    this.onChanged,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;

  static const _items = <(int?, String)>[
    (400, '400'),
    (300, '300'),
    (200, '200'),
    (null, BalmiCopy.specFree),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _chip(_items[i].$1, _items[i].$2)),
        ],
      ],
    );
  }

  Widget _chip(int? spec, String label) {
    final on = spec == value;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: Material(
        color: on ? BalmiColors.potato : BalmiColors.mist,
        shape: StadiumBorder(
          side: BorderSide(color: on ? BalmiColors.potato : Colors.transparent),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onChanged == null ? null : () => onChanged!(spec),
          child: SizedBox(
            height: 34,
            child: Center(
              child: Text(
                label,
                style: BalmiTheme.body(
                  size: 12,
                  weight: FontWeight.w800,
                  color: on ? Colors.white : BalmiColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
