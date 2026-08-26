import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/insets.dart';
import '../core/theme.dart';

/// Compact icon dock — not a labeled tab strip.
class BalmiDock extends StatelessWidget {
  const BalmiDock({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  /// Visible pill height (icons row).
  static const double barHeight = 52;

  static const double _topPad = 2;
  static const double _bottomPadExtra = 12;
  static const double _horizontalPad = 32;

  /// Total vertical space the dock occupies (pads + bar + system nav inset).
  ///
  /// Body content and modal sheets must clear this so CTAs are not hidden
  /// behind the floating dock.
  static double extent(BuildContext context) {
    return _topPad + barHeight + systemNavBottomInset(context) + _bottomPadExtra;
  }

  static const items = <(IconData, IconData, String)>[
    (Icons.radio_button_checked, Icons.radio_button_unchecked, BalmiCopy.recordTab),
    (Icons.history, Icons.history_outlined, BalmiCopy.workoutLogTab),
    (Icons.map, Icons.map_outlined, BalmiCopy.mapTab),
    (Icons.more_horiz, Icons.more_horiz, BalmiCopy.moreTab),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = systemNavBottomInset(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalPad,
        _topPad,
        _horizontalPad,
        bottom + _bottomPadExtra,
      ),
      child: Material(
        color: BalmiColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) _item(i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final active = index == i;
    final spec = items[i];
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: spec.$3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onChanged(i),
          child: Center(
            child: Icon(
              active ? spec.$1 : spec.$2,
              size: active ? 26 : 24,
              color: active ? BalmiColors.potato : BalmiColors.sub,
            ),
          ),
        ),
      ),
    );
  }
}
