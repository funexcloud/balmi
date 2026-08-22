import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../domain/engines/farm_life.dart';
import '../domain/engines/land_city.dart';

/// Drawn farm tableau — buildings and raised herds as shapes, not map pins.
class FarmScene extends StatelessWidget {
  const FarmScene({
    super.key,
    required this.buildings,
    required this.herds,
    this.caredToday = false,
    this.hasLand = false,
    this.height = 240,
  });

  final List<FarmKind> buildings;
  final List<HerdKind> herds;
  final bool caredToday;
  final bool hasLand;
  final double height;

  bool get _emptyYard => buildings.isEmpty && herds.isEmpty;

  String get semanticsLabel {
    if (_emptyYard) return BalmiCopy.landNoPath;
    final parts = <String>[
      for (final k in buildings) k.label,
    ];
    for (final kind in HerdKind.tiers) {
      final n = herds.where((h) => h == kind).length;
      if (n > 0) parts.add('${kind.label} $n');
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: FarmScenePainter(
                  buildings: buildings,
                  herds: herds,
                  caredToday: caredToday,
                ),
              ),
              if (_emptyYard)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          BalmiCopy.landNoPath,
                          textAlign: TextAlign.center,
                          style: BalmiTheme.body(
                            size: 13,
                            weight: FontWeight.w800,
                            color: BalmiColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          BalmiCopy.landWalkHint,
                          textAlign: TextAlign.center,
                          style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!hasLand)
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Text(
                      BalmiCopy.landNoPath,
                      style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FarmScenePainter extends CustomPainter {
  FarmScenePainter({
    required this.buildings,
    required this.herds,
    required this.caredToday,
  });

  final List<FarmKind> buildings;
  final List<HerdKind> herds;
  final bool caredToday;

  bool _has(FarmKind kind) => buildings.contains(kind);

  int _shown(HerdKind kind) =>
      herdOnStage(kind, herds.where((h) => h == kind).length);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _sky(canvas, w, h);
    _hills(canvas, w, h);
    _ground(canvas, w, h);
    _path(canvas, w, h);

    if (_has(FarmKind.pastureFence)) _fence(canvas, w, h);
    if (_has(FarmKind.barn)) _barn(canvas, Offset(w * 0.16, h * 0.48), w * 0.22);
    if (_has(FarmKind.farmhouse)) {
      _house(canvas, Offset(w * 0.52, h * 0.46), w * 0.2);
    }
    if (_has(FarmKind.villageStore)) {
      _store(canvas, Offset(w * 0.82, h * 0.47), w * 0.2);
    }

    final life = caredToday ? 1.0 : 0.55;
    _sheep(canvas, w, h, _shown(HerdKind.sheep), life);
    _chickens(canvas, w, h, _shown(HerdKind.chicken), life);
    _gardens(canvas, w, h, _shown(HerdKind.garden), life);
    _cattle(canvas, w, h, _shown(HerdKind.cattle), life);
  }

  void _sky(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h * 0.56);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3E6D4), BalmiColors.paper, Color(0xFFE8D4C0)],
        ).createShader(rect),
    );
  }

  void _hills(Canvas canvas, double w, double h) {
    final far = Paint()..color = const Color(0xFFB8C4A8);
    final near = Paint()..color = const Color(0xFF9AAB86);
    final p1 = Path()
      ..moveTo(0, h * 0.46)
      ..quadraticBezierTo(w * 0.22, h * 0.34, w * 0.48, h * 0.46)
      ..quadraticBezierTo(w * 0.7, h * 0.54, w, h * 0.42)
      ..lineTo(w, h * 0.56)
      ..lineTo(0, h * 0.56)
      ..close();
    canvas.drawPath(p1, far);
    final p2 = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.35, h * 0.42, w * 0.7, h * 0.52)
      ..lineTo(w, h * 0.5)
      ..lineTo(w, h * 0.56)
      ..lineTo(0, h * 0.56)
      ..close();
    canvas.drawPath(p2, near);
  }

  void _ground(Canvas canvas, double w, double h) {
    final grass = Rect.fromLTWH(0, h * 0.5, w, h * 0.5);
    canvas.drawRect(
      grass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FA37A), BalmiColors.sage, Color(0xFF667856)],
        ).createShader(grass),
    );
    final tuft = Paint()
      ..color = const Color(0xFF6F825C)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final x = w * (0.04 + (i * 0.053) % 0.94);
      final y = h * (0.62 + ((i * 17) % 9) * 0.03);
      canvas.drawLine(Offset(x, y), Offset(x - 3, y - 6), tuft);
      canvas.drawLine(Offset(x, y), Offset(x + 3, y - 5), tuft);
    }
  }

  void _path(Canvas canvas, double w, double h) {
    final dirt = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.4, h * 0.72, w, h * 0.8)
      ..lineTo(w, h * 0.9)
      ..quadraticBezierTo(w * 0.4, h * 0.82, 0, h * 0.96)
      ..close();
    canvas.drawPath(dirt, Paint()..color = const Color(0xFFC9A06A));
  }

  void _fence(Canvas canvas, double w, double h) {
    final rail = Paint()
      ..color = BalmiColors.plum
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final post = Paint()..color = BalmiColors.ink;
    final y1 = h * 0.56;
    final y2 = h * 0.61;
    canvas.drawLine(Offset(w * 0.03, y1), Offset(w * 0.46, y1), rail);
    canvas.drawLine(Offset(w * 0.03, y2), Offset(w * 0.46, y2), rail);
    for (var i = 0; i < 8; i++) {
      final x = w * (0.04 + i * 0.058);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, h * 0.585), width: 4, height: h * 0.09),
          const Radius.circular(1),
        ),
        post,
      );
    }
  }

  void _barn(Canvas canvas, Offset c, double span) {
    final body = Rect.fromCenter(center: c, width: span, height: span * 0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4)),
      Paint()..color = BalmiColors.plum,
    );
    final roof = Path()
      ..moveTo(body.left - 6, body.top + 8)
      ..lineTo(body.center.dx, body.top - span * 0.28)
      ..lineTo(body.right + 6, body.top + 8)
      ..close();
    canvas.drawPath(roof, Paint()..color = BalmiColors.ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(c.dx, body.bottom - 8),
          width: span * 0.22,
          height: 18,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = BalmiColors.amber,
    );
  }

  void _house(Canvas canvas, Offset c, double span) {
    final body = Rect.fromCenter(center: c, width: span * 0.86, height: span * 0.56);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()..color = const Color(0xFFF4E8D6),
    );
    final roof = Path()
      ..moveTo(body.left - 4, body.top + 6)
      ..lineTo(body.center.dx, body.top - span * 0.22)
      ..lineTo(body.right + 4, body.top + 6)
      ..close();
    canvas.drawPath(roof, Paint()..color = BalmiColors.plum);
    canvas.drawCircle(
      Offset(body.left + 14, body.center.dy),
      5,
      Paint()..color = BalmiColors.amber,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.right - 22, body.bottom - 20, 12, 20),
        const Radius.circular(1),
      ),
      Paint()..color = BalmiColors.ink,
    );
  }

  void _store(Canvas canvas, Offset c, double span) {
    final body = Rect.fromCenter(center: c, width: span, height: span * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()..color = const Color(0xFF5A4638),
    );
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.top - 8, body.width, 10),
      Paint()..color = BalmiColors.amber,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(c.dx, body.bottom - 8),
          width: span * 0.28,
          height: 16,
        ),
        const Radius.circular(1),
      ),
      Paint()..color = BalmiColors.paper,
    );
  }

  void _sheep(Canvas canvas, double w, double h, int n, double life) {
    final fill = Paint()..color = BalmiColors.paper.withValues(alpha: life);
    final line = Paint()
      ..color = BalmiColors.ink.withValues(alpha: life)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final head = Paint()..color = BalmiColors.ink.withValues(alpha: life);
    for (var i = 0; i < n; i++) {
      final t = (i + 1) / (n + 1);
      final x = w * (0.08 + t * 0.32 + (i.isOdd ? 0.02 : 0));
      final y = h * (0.68 + (i % 3) * 0.07) + (caredToday ? 0 : 3);
      final body = Rect.fromCenter(center: Offset(x, y), width: 22, height: 14);
      canvas.drawOval(body, fill);
      canvas.drawOval(body, line);
      canvas.drawCircle(Offset(x + 9, y - 2), 4.2, head);
      canvas.drawCircle(Offset(x + 11, y - 5), 1.6, fill);
      final legs = Paint()
        ..color = BalmiColors.ink.withValues(alpha: life)
        ..strokeWidth = 1.4;
      for (final dx in [-6.0, -2.0, 2.0, 6.0]) {
        canvas.drawLine(Offset(x + dx, y + 5), Offset(x + dx, y + 11), legs);
      }
    }
  }

  void _chickens(Canvas canvas, double w, double h, int n, double life) {
    final body = Paint()..color = BalmiColors.amber.withValues(alpha: life);
    final ink = Paint()..color = BalmiColors.ink.withValues(alpha: life);
    final beak = Paint()..color = BalmiColors.plum.withValues(alpha: life);
    for (var i = 0; i < n; i++) {
      final x = w * (0.2 + (i % 4) * 0.055);
      final y = h * (0.58 + (i ~/ 4) * 0.06) + (caredToday ? 0 : 2);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 11, height: 8), body);
      canvas.drawCircle(Offset(x + 4, y - 3), 3.2, body);
      canvas.drawCircle(Offset(x + 5, y - 3.4), 0.8, ink);
      final tri = Path()
        ..moveTo(x + 7, y - 3)
        ..lineTo(x + 11, y - 2)
        ..lineTo(x + 7, y - 1)
        ..close();
      canvas.drawPath(tri, beak);
      canvas.drawLine(
        Offset(x - 2, y + 3),
        Offset(x - 2, y + 7),
        Paint()
          ..color = BalmiColors.ink.withValues(alpha: life)
          ..strokeWidth = 1,
      );
    }
  }

  void _gardens(Canvas canvas, double w, double h, int n, double life) {
    for (var i = 0; i < n; i++) {
      final left = w * (0.46 + (i % 2) * 0.12);
      final top = h * (0.64 + (i ~/ 2) * 0.1);
      final bed = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w * 0.1, h * 0.08),
        const Radius.circular(3),
      );
      canvas.drawRRect(bed, Paint()..color = const Color(0xFF8B6A3E).withValues(alpha: life));
      final sprout = Paint()
        ..color = BalmiColors.sage.withValues(alpha: life)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (var r = 0; r < 3; r++) {
        final y = top + 6 + r * 7;
        canvas.drawLine(Offset(left + 6, y), Offset(left + w * 0.1 - 6, y), sprout);
        for (var d = 0; d < 3; d++) {
          canvas.drawCircle(
            Offset(left + 10 + d * 10, y - 3),
            2.2,
            Paint()..color = const Color(0xFF5E734C).withValues(alpha: life),
          );
        }
      }
    }
  }

  void _cattle(Canvas canvas, double w, double h, int n, double life) {
    final hide = Paint()..color = const Color(0xFF4A342C).withValues(alpha: life);
    final horn = Paint()
      ..color = BalmiColors.paper.withValues(alpha: life)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final x = w * (0.7 + i * 0.09);
      final y = h * (0.7 + (i.isOdd ? 0.06 : 0)) + (caredToday ? 0 : 3);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 30, height: 16), hide);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 12, y - 3), width: 12, height: 10),
        hide,
      );
      canvas.drawLine(Offset(x + 10, y - 8), Offset(x + 7, y - 12), horn);
      canvas.drawLine(Offset(x + 14, y - 8), Offset(x + 17, y - 12), horn);
      final legs = Paint()
        ..color = BalmiColors.ink.withValues(alpha: life)
        ..strokeWidth = 2;
      for (final dx in [-8.0, -3.0, 4.0, 9.0]) {
        canvas.drawLine(Offset(x + dx, y + 6), Offset(x + dx, y + 14), legs);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FarmScenePainter old) {
    return old.caredToday != caredToday ||
        !_same(old.buildings, buildings) ||
        !_same(old.herds, herds);
  }

  bool _same<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
