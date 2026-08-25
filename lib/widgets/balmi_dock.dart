import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/insets.dart';
import '../core/theme.dart';

/// Compact icon dock — not a labeled tab strip.
class BalmiDock extends StatelessWidget {
  const BalmiDock({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

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
      padding: EdgeInsets.fromLTRB(32, 2, 32, bottom + 12),
      child: Material(
        color: BalmiColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 52,
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
