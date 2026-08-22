import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/models/activity.dart';

class ActivityPills extends StatelessWidget {
  const ActivityPills({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ActivityKind value;
  final ValueChanged<ActivityKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final a in ActivityKind.selectable)
          GestureDetector(
            onTap: () => onChanged(a),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: value == a ? BalmiColors.plum : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: BalmiColors.plum, width: 2),
              ),
              child: Text(
                a.label,
                style: BalmiTheme.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: value == a ? BalmiColors.paper : BalmiColors.plum,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
