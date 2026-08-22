import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Bottom space that clears 3-button nav, gesture nav, and the home indicator.
///
/// `SafeArea` alone uses [MediaQueryData.padding], which is often 0 on
/// Android gesture navigation. Take the max of padding / viewPadding /
/// systemGestureInsets, then add [extra] (16–24).
double systemNavBottomInset(BuildContext context) {
  final mq = MediaQuery.of(context);
  return [
    mq.padding.bottom,
    mq.viewPadding.bottom,
    mq.systemGestureInsets.bottom,
  ].reduce(math.max);
}

double primaryCtaBottomPadding(
  BuildContext context, {
  double extra = BalmiTheme.extraNavPad,
}) {
  return systemNavBottomInset(context) + extra;
}
