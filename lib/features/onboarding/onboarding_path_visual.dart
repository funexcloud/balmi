import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Stylized trail on a soft map plane — path only, no people/shoe art.
class OnboardingPathVisual extends StatelessWidget {
  const OnboardingPathVisual({
    super.key,
    required this.progress,
    this.variant = OnboardingPathVariant.single,
    this.showEndMark = true,
    this.height = 200,
    this.networkPhase = 0,
    this.dimmed = false,
  });

  /// 0–1 draw amount for the primary path.
  final double progress;
  final OnboardingPathVariant variant;
  final bool showEndMark;
  final double height;
  /// 0=5G, 1=weak, 2=none — only used on [OnboardingPathVariant.offline].
  final int networkPhase;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dimmed
                ? const [Color(0xFFEDE8E3), Color(0xFFE2DDD7)]
                : const [Color(0xFFF7F1EB), Color(0xFFEEE7DF), Color(0xFFE8F0EA)],
          ),
          border: Border.all(color: BalmiColors.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            painter: _MapPathPainter(
              progress: progress.clamp(0.0, 1.0),
              variant: variant,
              showEndMark: showEndMark,
              networkPhase: networkPhase,
              dimmed: dimmed,
            ),
          ),
        ),
      ),
    );
  }
}

enum OnboardingPathVariant { single, offline, recovered, merged }

class _MapPathPainter extends CustomPainter {
  _MapPathPainter({
    required this.progress,
    required this.variant,
    required this.showEndMark,
    required this.networkPhase,
    required this.dimmed,
  });

  final double progress;
  final OnboardingPathVariant variant;
  final bool showEndMark;
  final int networkPhase;
  final bool dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    if (variant == OnboardingPathVariant.merged) {
      _paintMerged(canvas, size);
      return;
    }

    final pts = _primaryPoints(size);
    _strokePath(
      canvas,
      pts,
      progress,
      color: dimmed
          ? BalmiColors.potato.withValues(alpha: 0.35)
          : BalmiColors.potato,
      width: 3.2,
    );

    if (pts.isNotEmpty) {
      _dot(canvas, pts.first, BalmiColors.ink.withValues(alpha: 0.55), 5);
      if (showEndMark && progress > 0.08) {
        final end = _pointAlong(pts, progress);
        _dot(canvas, end, BalmiColors.potatoDk, 6.5);
        if (variant == OnboardingPathVariant.recovered) {
          _balmiMark(canvas, end);
        }
      }
    }

    if (variant == OnboardingPathVariant.offline) {
      _networkGlyph(canvas, size);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BalmiColors.ink.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  List<Offset> _primaryPoints(Size size) {
    final w = size.width;
    final h = size.height;
    return [
      Offset(w * 0.12, h * 0.72),
      Offset(w * 0.28, h * 0.58),
      Offset(w * 0.42, h * 0.62),
      Offset(w * 0.55, h * 0.42),
      Offset(w * 0.68, h * 0.48),
      Offset(w * 0.82, h * 0.28),
    ];
  }

  void _paintMerged(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final walk = [
      Offset(w * 0.10, h * 0.70),
      Offset(w * 0.30, h * 0.62),
      Offset(w * 0.48, h * 0.55),
      Offset(w * 0.66, h * 0.50),
      Offset(w * 0.84, h * 0.46),
    ];
    final run = [
      Offset(w * 0.12, h * 0.78),
      Offset(w * 0.32, h * 0.68),
      Offset(w * 0.52, h * 0.42),
      Offset(w * 0.70, h * 0.34),
      Offset(w * 0.86, h * 0.30),
    ];
    final track = [
      Offset(w * 0.22, h * 0.36),
      Offset(w * 0.38, h * 0.28),
      Offset(w * 0.55, h * 0.30),
      Offset(w * 0.70, h * 0.38),
      Offset(w * 0.58, h * 0.48),
      Offset(w * 0.40, h * 0.46),
      Offset(w * 0.28, h * 0.38),
    ];
    _strokePath(canvas, walk, progress, color: BalmiColors.sage, width: 2.6);
    _strokePath(canvas, run, progress, color: BalmiColors.potato, width: 3.0);
    _strokePath(canvas, track, progress, color: BalmiColors.plumLt, width: 2.4);
    if (progress > 0.2) {
      final end = _pointAlong(run, progress);
      _dot(canvas, end, BalmiColors.potatoDk, 7);
      _balmiMark(canvas, end);
    }
  }

  void _strokePath(
    Canvas canvas,
    List<Offset> pts,
    double t, {
    required Color color,
    required double width,
  }) {
    if (pts.length < 2 || t <= 0) return;
    final path = _pathFrom(pts);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var remain = total * t;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    for (final m in metrics) {
      final take = math.min(remain, m.length);
      if (take <= 0) break;
      canvas.drawPath(m.extractPath(0, take), paint);
      remain -= take;
    }
  }

  Path _pathFrom(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      if (i == 1) {
        path.lineTo(mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  Offset _pointAlong(List<Offset> pts, double t) {
    final path = _pathFrom(pts);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return pts.last;
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var target = total * t.clamp(0.0, 1.0);
    for (final m in metrics) {
      if (target <= m.length) {
        return m.getTangentForOffset(target)?.position ?? pts.last;
      }
      target -= m.length;
    }
    return pts.last;
  }

  void _dot(Canvas canvas, Offset c, Color color, double r) {
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _balmiMark(Canvas canvas, Offset c) {
    final r = Rect.fromCenter(center: c.translate(0, -16), width: 22, height: 22);
    final bg = Paint()..color = BalmiColors.potato;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(7)),
      bg,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'B',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          height: 1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
  }

  void _networkGlyph(Canvas canvas, Size size) {
    final origin = Offset(size.width - 36, 28);
    const bars = 4;
    for (var i = 0; i < bars; i++) {
      final on = networkPhase == 0
          ? true
          : networkPhase == 1
              ? i < 2
              : false;
      final h = 6.0 + i * 3.5;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + i * 5.5, origin.dy - h, 3.5, h),
        const Radius.circular(1),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = on
              ? BalmiColors.sage
              : BalmiColors.ink.withValues(alpha: 0.18),
      );
    }
    if (networkPhase >= 2) {
      final slash = Paint()
        ..color = BalmiColors.plum
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        origin.translate(-2, -14),
        origin.translate(22, 4),
        slash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPathPainter old) =>
      old.progress != progress ||
      old.variant != variant ||
      old.showEndMark != showEndMark ||
      old.networkPhase != networkPhase ||
      old.dimmed != dimmed;
}
