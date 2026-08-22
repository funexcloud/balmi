import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'balmi_wordmark.dart';

class BalmiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BalmiAppBar({
    super.key,
    this.title,
    this.actions,
    this.showWordmark = false,
  });

  final String? title;
  final List<Widget>? actions;
  final bool showWordmark;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: BalmiColors.paper,
      foregroundColor: BalmiColors.ink,
      elevation: 0,
      titleSpacing: 8,
      title: showWordmark
          ? const BalmiWordmark(height: 24)
          : Text(
              title ?? '',
              style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
            ),
      actions: actions,
    );
  }
}
