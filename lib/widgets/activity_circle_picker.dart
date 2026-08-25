import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/models/activity.dart';
import 'activity_pills.dart';

/// Long-press radial picker for activity type on the recording map controls.
Future<ActivityKind?> showActivityCirclePicker({
  required BuildContext context,
  required ActivityKind selected,
  Offset? origin,
}) {
  final anchor = origin ??
      (Overlay.of(context).context.findRenderObject() as RenderBox?)
          ?.localToGlobal(Offset.zero) ??
      Offset.zero;

  return showGeneralDialog<ActivityKind>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'activity picker',
    barrierColor: Colors.black.withValues(alpha: 0.18),
    pageBuilder: (ctx, _, __) {
      return _ActivityCirclePickerOverlay(
        anchor: anchor,
        selected: selected,
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return FadeTransition(opacity: anim, child: child);
    },
  );
}

class _ActivityCirclePickerOverlay extends StatelessWidget {
  const _ActivityCirclePickerOverlay({
    required this.anchor,
    required this.selected,
  });

  final Offset anchor;
  final ActivityKind selected;

  static const _radius = 92.0;
  static const _tileSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final kinds = ActivityKind.selectable;
    final startAngle = -math.pi / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          for (var i = 0; i < kinds.length; i++)
            _tile(context, kinds[i], i, kinds.length, startAngle),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    ActivityKind kind,
    int index,
    int count,
    double startAngle,
  ) {
    final angle = startAngle + (2 * math.pi * index / count);
    final dx = anchor.dx + _radius * math.cos(angle) - _tileSize / 2;
    final dy = anchor.dy + _radius * math.sin(angle) - _tileSize / 2;
    final on = kind == selected;

    return Positioned(
      left: dx,
      top: dy,
      child: Semantics(
        button: true,
        selected: on,
        label: kind.label,
        child: Material(
          color: on ? BalmiColors.potato : BalmiColors.surface,
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(kind),
            child: SizedBox(
              width: _tileSize,
              height: _tileSize,
              child: Icon(
                ActivityPills.iconOf(kind),
                size: 22,
                color: on ? Colors.white : BalmiColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
