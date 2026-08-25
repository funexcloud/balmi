import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Icon-only round control. Not a labeled menu item.
class CircleAction extends StatelessWidget {
  const CircleAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.filled = false,
    this.size = 52,
  });

  final IconData icon;
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
            child: Icon(icon, size: size * 0.42, color: fg),
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
