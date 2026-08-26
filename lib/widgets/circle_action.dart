import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'balmi_dock.dart';

/// Icon-only round control. Not a labeled menu item.
class CircleAction extends StatelessWidget {
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
  final VoidCallback? onLongPress;
  final bool filled;
  final double size;

  /// Same diameter as the home play control.
  static const double playSize = 68;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? BalmiColors.potato : BalmiColors.surface;
    final fg = filled ? Colors.white : BalmiColors.ink;
    final iconSize = size * 0.42;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        elevation: filled ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: glyph ??
                  Icon(icon, size: iconSize, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal sheet that sits **above** the floating [BalmiDock].
///
/// Default [showModalBottomSheet] anchors to the screen bottom, so the sheet
/// (and its CTAs) end up behind the dock. We clear [BalmiDock.extent] under a
/// transparent sheet chrome so content paints above the dock.
Future<void> showBalmiSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final dockClearance = BalmiDock.extent(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: dockClearance),
        child: Material(
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
            ],
          ),
        ),
      );
    },
  );
}
