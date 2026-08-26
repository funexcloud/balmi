import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Lucide [LocateFixed] — 24×24 viewBox, stroke 2, round cap/join.
///
/// Crosshair with outer ring + inner fixed point. Used for GPS status chrome.
class LocateFixedIcon extends StatelessWidget {
  const LocateFixedIcon({
    super.key,
    this.size = 16,
    this.color = BalmiColors.ink,
    this.strokeWidth = 2,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LocateFixedPainter(color: color, strokeWidth: strokeWidth),
        size: Size.square(size),
      ),
    );
  }
}

class _LocateFixedPainter extends CustomPainter {
  const _LocateFixedPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Arms: left / right / top / bottom
    canvas.drawLine(Offset(2 * s, 12 * s), Offset(5 * s, 12 * s), paint);
    canvas.drawLine(Offset(19 * s, 12 * s), Offset(22 * s, 12 * s), paint);
    canvas.drawLine(Offset(12 * s, 2 * s), Offset(12 * s, 5 * s), paint);
    canvas.drawLine(Offset(12 * s, 19 * s), Offset(12 * s, 22 * s), paint);

    canvas.drawCircle(Offset(12 * s, 12 * s), 7 * s, paint);
    canvas.drawCircle(Offset(12 * s, 12 * s), 3 * s, paint);
  }

  @override
  bool shouldRepaint(covariant _LocateFixedPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
