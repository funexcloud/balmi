import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
    // Custom overlay owns dismiss; keep the route barrier from eating the
    // long-press pointer-up that opened this dialog.
    barrierDismissible: false,
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

class _ActivityCirclePickerOverlay extends StatefulWidget {
  const _ActivityCirclePickerOverlay({
    required this.anchor,
    required this.selected,
  });

  final Offset anchor;
  final ActivityKind selected;

  @override
  State<_ActivityCirclePickerOverlay> createState() =>
      _ActivityCirclePickerOverlayState();
}

class _ActivityCirclePickerOverlayState
    extends State<_ActivityCirclePickerOverlay> {
  static const _radius = 92.0;
  static const _tileSize = 48.0;

  /// Ignore barrier taps until the opening gesture has fully cleared.
  var _dismissArmed = false;

  @override
  void initState() {
    super.initState();
    // Arm after the frame that presented us + one more frame so any residual
    // pointer-up from the long-press that opened the picker cannot dismiss it.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _dismissArmed = true);
      });
    });
  }

  void _dismiss() {
    if (!_dismissArmed) return;
    Navigator.of(context).pop();
  }

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
              onTap: _dismiss,
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
    final dx = widget.anchor.dx + _radius * math.cos(angle) - _tileSize / 2;
    final dy = widget.anchor.dy + _radius * math.sin(angle) - _tileSize / 2;
    final on = kind == widget.selected;

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
              child: Center(
                child: ActivityPills.glyphOf(
                  kind,
                  size: 22,
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
