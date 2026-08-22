import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../domain/models/activity.dart';

/// Two equal rows of six activity tiles (not a ragged wrap).
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
    return Material(
      color: on ? BalmiColors.plum : Colors.white,
      shape: const StadiumBorder(
        side: BorderSide(color: BalmiColors.plum, width: 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => onChanged(a),
        child: SizedBox(
          height: 38,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  a.label,
                  maxLines: 1,
                  style: BalmiTheme.body(
                    size: 13,
                    weight: FontWeight.w800,
                    color: on ? BalmiColors.paper : BalmiColors.plum,
                  ),
                ),
              ),
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
    return Material(
      color: on ? BalmiColors.plum : Colors.white,
      shape: const StadiumBorder(
        side: BorderSide(color: BalmiColors.plum, width: 1.2),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onChanged == null ? null : () => onChanged!(spec),
        child: SizedBox(
          height: 32,
          child: Center(
            child: Text(
              label,
              style: BalmiTheme.body(
                size: 12,
                weight: FontWeight.w800,
                color: on ? BalmiColors.paper : BalmiColors.plum,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
