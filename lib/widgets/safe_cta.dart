import 'package:flutter/material.dart';

import '../core/insets.dart';
import '../core/theme.dart';

/// Pins a primary (and optional secondary) CTA above the Android nav /
/// gesture bar. Use on screens that do **not** already sit above [BalmiBottomNav].
class SafeCtaBar extends StatelessWidget {
  const SafeCtaBar({
    super.key,
    required this.child,
    this.extra = BalmiTheme.extraNavPad,
    this.horizontal = 20,
  });

  final Widget child;
  final double extra;
  final double horizontal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        8,
        horizontal,
        primaryCtaBottomPadding(context, extra: extra),
      ),
      child: child,
    );
  }
}

class SafePrimaryButton extends StatelessWidget {
  const SafePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.extra = BalmiTheme.extraNavPad,
  });

  final String label;
  final VoidCallback? onPressed;
  final double extra;

  @override
  Widget build(BuildContext context) {
    return SafeCtaBar(
      extra: extra,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
