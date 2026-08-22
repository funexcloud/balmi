import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/stubs/future_features.dart';

/// F5 territory preview. Visual language from 목업 v2 — not live H3 deeds.
class LandPreviewScreen extends StatelessWidget {
  const LandPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      children: [
        Text(
          BalmiCopy.registryKicker,
          style: BalmiTheme.tracked(
            size: 11,
            trackingEm: 0.28,
            color: BalmiColors.plum,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(BalmiCopy.landTitle, style: BalmiTheme.body(size: 24, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('0', style: BalmiTheme.num(size: 44)),
            Text('㎡', style: BalmiTheme.num(size: 17)),
            const SizedBox(width: 10),
            Text(
              BalmiCopy.landEmptyArea,
              style: BalmiTheme.body(size: 14, color: BalmiColors.sub),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          BalmiCopy.landPreview,
          style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
        ),
        const SizedBox(height: 10),
        const AspectRatio(
          aspectRatio: 380 / 290,
          child: CustomPaint(painter: _CadastralPainter()),
        ),
        const SizedBox(height: 10),
        Text(
          BalmiCopy.recentDeed,
          style: BalmiTheme.tracked(
            size: 11.5,
            trackingEm: 0.14,
            color: BalmiColors.sub,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          BalmiCopy.landEmptyRecent,
          style: BalmiTheme.body(size: 14, color: BalmiColors.sub),
        ),
        const SizedBox(height: 12),
        Text(BalmiCopy.landFoot, style: BalmiTheme.body(size: 11, color: BalmiColors.sub, height: 1.6)),
        const SizedBox(height: 10),
        Text(BalmiCopy.e01, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
        Text(BalmiCopy.e02, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
        Text(BalmiCopy.e03, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
        Text(BalmiCopy.e04, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
        if (!FutureFeatures.territoryEnabled) const SizedBox(height: 8),
      ],
    );
  }
}

class _CadastralPainter extends CustomPainter {
  const _CadastralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 380;
    final sy = size.height / 290;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    canvas.drawRect(Offset.zero & size, Paint()..color = BalmiColors.paper);

    final grid = Paint()
      ..color = BalmiColors.line
      ..strokeWidth = 0.7;
    for (var i = 0; i < 12; i++) {
      canvas.drawLine(p(i * 34.0, 0), p(i * 34.0, 290), grid);
    }
    for (var i = 0; i < 9; i++) {
      canvas.drawLine(p(0, i * 33.0), p(380, i * 33.0), grid);
    }

    Path poly(List<double> xy) {
      final path = Path()..moveTo(xy[0] * sx, xy[1] * sy);
      for (var i = 2; i < xy.length; i += 2) {
        path.lineTo(xy[i] * sx, xy[i + 1] * sy);
      }
      path.close();
      return path;
    }

    final other = Paint()
      ..color = BalmiColors.plumLt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(
      poly([30, 40, 130, 28, 150, 95, 60, 110]),
      other..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(poly([250, 175, 350, 165, 356, 245, 262, 255]), other);

    // Preview parcels only — faded, not claimed area.
    final fill = Paint()..color = BalmiColors.plum.withValues(alpha: 0.10);
    final stroke = Paint()
      ..color = BalmiColors.plum.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(poly([160, 58, 300, 46, 320, 138, 180, 152]), fill);
    canvas.drawPath(poly([160, 58, 300, 46, 320, 138, 180, 152]), stroke);
    canvas.drawPath(poly([55, 148, 175, 162, 160, 250, 45, 236]), fill);
    canvas.drawPath(poly([55, 148, 175, 162, 160, 250, 45, 236]), stroke);

    final loop = Paint()
      ..color = BalmiColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(poly([200, 185, 290, 195, 275, 262, 195, 255]), loop);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    void label(String t, double x, double y, {double size = 12, FontWeight w = FontWeight.w800}) {
      tp
        ..text = TextSpan(
          text: t,
          style: TextStyle(
            fontFamily: BalmiFonts.wordmark,
            fontSize: size,
            fontWeight: w,
            color: BalmiColors.ink,
          ),
        )
        ..layout();
      tp.paint(canvas, p(x, y));
    }

    label(BalmiCopy.todayLoop, 220, 220, size: 11, w: FontWeight.w700);
    label('미리보기', 212, 112);
    label('미리보기', 82, 204);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
