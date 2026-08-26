import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Icon-only round control. Not a labeled menu item.
class CircleAction extends StatefulWidget {
  const CircleAction({
    super.key,
    this.icon,
    this.glyph,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.filled = false,
    this.size = 52,
  }) : assert(icon != null || glyph != null, 'Provide icon or glyph');

  /// Material icon. Ignored when [glyph] is set.
  final IconData? icon;

  /// Custom glyph (e.g. [TrackIcon]). Preferred over [icon] when both given.
  final Widget? glyph;

  final String label;
  final VoidCallback onTap;

  /// Invoked when the long-press finger lifts (not when the timeout fires).
  ///
  /// Callers that open a dialog/picker from this callback must not show it
  /// while the pointer is still down — that dismisses a barrier immediately.
  final VoidCallback? onLongPress;
  final bool filled;
  final double size;

  /// Same diameter as the home play control.
  static const double playSize = 68;

  @override
  State<CircleAction> createState() => _CircleActionState();
}

class _CircleActionState extends State<CircleAction> {
  /// Long-press timeout fired; wait for pointer-up before invoking callback.
  var _armedLongPress = false;

  void _onPointerUp(PointerUpEvent _) {
    if (!_armedLongPress) return;
    _armedLongPress = false;
    widget.onLongPress?.call();
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _armedLongPress = false;
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled ? BalmiColors.potato : BalmiColors.surface;
    final fg = widget.filled ? Colors.white : BalmiColors.ink;
    final iconSize = widget.size * 0.42;
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        behavior: HitTestBehavior.deferToChild,
        onPointerUp: widget.onLongPress == null ? null : _onPointerUp,
        onPointerCancel: widget.onLongPress == null ? null : _onPointerCancel,
        child: Material(
          color: bg,
          elevation: widget.filled ? 0 : 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            // Arm only — actual [onLongPress] runs on pointer-up so a dialog
            // opened from the callback is not dismissed by the same gesture.
            onLongPress: widget.onLongPress == null
                ? null
                : () => _armedLongPress = true,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Center(
                child: widget.glyph ??
                    Icon(widget.icon, size: iconSize, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showBalmiSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: BalmiColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: builder,
  );
}
