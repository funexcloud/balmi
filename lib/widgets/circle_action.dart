import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'balmi_dock.dart';

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

/// Modal sheet that sits **above** the floating [BalmiDock].
///
/// Default [showModalBottomSheet] anchors to the screen bottom. Content must
/// clear [BalmiDock.extent], but the sheet chrome itself stays **opaque to the
/// bottom edge** so the dock is covered (not visible through a transparent gap
/// under the floating pill). Uses the root navigator so the barrier dims the
/// dock under the modal route.
///
/// Returns the value passed to [Navigator.pop], or `null` if dismissed.
Future<T?> showBalmiSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  final dockClearance = BalmiDock.extent(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: true,
    // Transparent route chrome so the rounded Material corners show;
    // the Material itself is opaque through the dock band.
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black54,
    builder: (ctx) {
      final keyboard = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Material(
          key: const ValueKey('balmi-sheet-chrome'),
          color: BalmiColors.surface,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BalmiColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              builder(ctx),
              // Opaque dock cover — solid surface, not a transparent pad.
              SizedBox(
                key: const ValueKey('balmi-sheet-dock-cover'),
                height: dockClearance,
              ),
            ],
          ),
        ),
      );
    },
  );
}
