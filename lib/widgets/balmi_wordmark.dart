import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Lowercase **balmi** + one heartbeat peak between **m** and **i** (규정 01).
class BalmiWordmark extends StatelessWidget {
  const BalmiWordmark({
    super.key,
    this.height = 26,
    this.dark = false,
  });

  final double height;
  final bool dark;

  static const _vbW = 150.0;
  static const _vbH = 52.0;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? BalmiColors.paper : BalmiColors.ink;
    final pulse = dark ? BalmiColors.amber : BalmiColors.plum;
    return Semantics(
      label: 'balmi',
      child: SizedBox(
        height: height,
        width: height * (_vbW / _vbH),
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: _vbW,
            height: _vbH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 2,
                  top: 2,
                  child: Text(
                    'balmi',
                    style: TextStyle(
                      fontFamily: BalmiFonts.wordmark,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      height: 1,
                      letterSpacing: -0.5,
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  top: 4,
                  child: Text(
                    'balmi',
                    style: TextStyle(
                      fontFamily: BalmiFonts.wordmark,
                      fontFamilyFallback: BalmiFonts.fallbacks,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      height: 1,
                      letterSpacing: -0.5,
                      color: ink,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 20,
                  child: CustomPaint(
                    painter: _HeartbeatPainter(color: pulse, stroke: 2.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width divider: one peak only (규정: 피크 1회).
class HeartbeatDivider extends StatelessWidget {
  const HeartbeatDivider({
    super.key,
    this.color = BalmiColors.plum,
    this.height = 20,
  });

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          painter: _HeartbeatPainter(color: color, stroke: 2.4, wide: true),
        ),
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  _HeartbeatPainter({
    required this.color,
    required this.stroke,
    this.wide = false,
  });

  final Color color;
  final double stroke;
  final bool wide;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (wide) {
      // Mockup: M0 13 H170 L182 13 L190 3 L200 19 L208 13 H340
      final sx = size.width / 340;
      final sy = size.height / 20;
      path
        ..moveTo(0, 13 * sy)
        ..lineTo(170 * sx, 13 * sy)
        ..lineTo(182 * sx, 13 * sy)
        ..lineTo(190 * sx, 3 * sy)
        ..lineTo(200 * sx, 19 * sy)
        ..lineTo(208 * sx, 13 * sy)
        ..lineTo(size.width, 13 * sy);
    } else {
      // Mockup wordmark: M3 42 H62 L68 42 L72 34 L77 47 L81 42 H138
      // Drawn in a 150×20 strip under the letters (peak between m and i).
      final sx = size.width / 150;
      final midY = size.height * 0.55;
      path
        ..moveTo(3 * sx, midY)
        ..lineTo(62 * sx, midY)
        ..lineTo(68 * sx, midY)
        ..lineTo(72 * sx, size.height * 0.12)
        ..lineTo(77 * sx, size.height * 0.92)
        ..lineTo(81 * sx, midY)
        ..lineTo(138 * sx, midY);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter old) =>
      old.color != color || old.stroke != stroke || old.wide != wide;
}
