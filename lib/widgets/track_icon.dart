import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Athletics track glyph — Material `Icons.stadium` is missing on some devices.
///
/// Drawn as a solid stadium-ring (even-odd outer/inner oval) so it stays
/// visible at small sizes and on every platform font/icon set.
class TrackIcon extends StatelessWidget {
  const TrackIcon({super.key, this.size = 22, this.color = BalmiColors.sub});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TrackPainter(color),
        size: Size.square(size),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Keep a readable ring thickness at badge sizes (~16px).
    final inset = (w * 0.10).clamp(1.2, w * 0.14);
    final lane = (w * 0.18).clamp(2.0, w * 0.22);

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset * 1.35, w - inset * 2, h - inset * 2.7),
      Radius.circular(h),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset + lane,
        inset * 1.35 + lane * 0.85,
        w - inset * 2 - lane * 2,
        h - inset * 2.7 - lane * 1.7,
      ),
      Radius.circular(h),
    );

    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(inner);

    canvas.drawPath(
      ring,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Short start/finish mark on the near straight — reads as a track, not a bagel.
    final markPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.08).clamp(1.2, 2.2)
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final midX = w * 0.5;
    final topY = inset * 1.35 + lane * 0.15;
    final botY = inset * 1.35 + lane * 0.85;
    canvas.drawLine(Offset(midX, topY), Offset(midX, botY), markPaint);
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) =>
      oldDelegate.color != color;
}
