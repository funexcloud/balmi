import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// Shared history line: date · activity · distance.
class SessionRow extends StatelessWidget {
  const SessionRow({
    super.key,
    required this.startedAt,
    required this.activityLabel,
    required this.distM,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final DateTime startedAt;
  final String activityLabel;
  final double distM;
  final String? trailing;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${formatDateTime(startedAt)} · $activityLabel · ${formatKm(distM)}km',
                style: BalmiTheme.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: selected ? BalmiColors.potato : BalmiColors.ink,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
              ),
          ],
        ),
      ),
    );
  }
}
