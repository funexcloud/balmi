import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../domain/engines/farm_life.dart';
import '../domain/engines/farm_time_of_day.dart';
import '../domain/engines/land_city.dart';

const farmWaterDuration = Duration(milliseconds: 900);

/// A small cared-for farm stage. Shapes only — no downloaded art.
class FarmScene extends StatefulWidget {
  const FarmScene({
    super.key,
    required this.buildings,
    required this.herds,
    this.caredToday = false,
    this.height = 268,
    this.watering = false,
    this.onWateringComplete,
    this.nowOverride,
    this.latitude,
  });

  final List<FarmKind> buildings;
  final List<HerdKind> herds;
  final bool caredToday;
  final double height;
  final bool watering;
  final VoidCallback? onWateringComplete;

  /// When set, sky phase is frozen for tests; no periodic refresh.
  final DateTime? nowOverride;

  /// Optional latitude from last GPS fix; defaults to central Korea.
  final double? latitude;

  @override
  State<FarmScene> createState() => _FarmSceneState();
}

class _FarmSceneState extends State<FarmScene> with SingleTickerProviderStateMixin {
  late final AnimationController _water;
  Timer? _skyTimer;
  late FarmSkyAppearance _sky;
  var _armed = false;
  var _notified = false;

  bool get _emptyYard => widget.buildings.isEmpty && widget.herds.isEmpty;

  String get semanticsLabel {
    if (_emptyYard) return BalmiCopy.landEmptyField;
    final parts = <String>[
      for (final k in widget.buildings) k.label,
    ];
    for (final kind in HerdKind.tiers) {
      final n = widget.herds.where((h) => h == kind).length;
      if (n > 0) parts.add('${kind.label} $n');
    }
    return parts.join(', ');
  }

  @override
  void initState() {
    super.initState();
    _sky = _resolveSky();
    _armSkyTimer();
    _water = AnimationController(vsync: this, duration: farmWaterDuration)
      ..addStatusListener(_onStatus);
    if (widget.watering) {
      _armed = true;
      _water.forward();
    }
  }

  FarmSkyAppearance _resolveSky() {
    return resolveFarmSky(
      now: widget.nowOverride ?? DateTime.now(),
      latitudeDeg: widget.latitude ?? kFarmDefaultLatitude,
    );
  }

  void _armSkyTimer() {
    _skyTimer?.cancel();
    if (widget.nowOverride != null) return;
    _skyTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _sky = _resolveSky());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.watering && MediaQuery.disableAnimationsOf(context)) {
      _skipMotion();
    }
  }

  @override
  void didUpdateWidget(covariant FarmScene old) {
    super.didUpdateWidget(old);
    if (widget.nowOverride != old.nowOverride ||
        widget.latitude != old.latitude) {
      setState(() => _sky = _resolveSky());
      _armSkyTimer();
    }
    if (widget.watering && !old.watering) {
      _armed = false;
      _notified = false;
      _play();
    }
    if (!widget.watering && old.watering) {
      _armed = false;
      _notified = false;
      _water.reset();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _notify();
  }

  void _notify() {
    if (_notified) return;
    _notified = true;
    widget.onWateringComplete?.call();
  }

  void _skipMotion() {
    if (_water.isAnimating) _water.stop();
    _armed = true;
    _notify();
  }

  void _play() {
    if (!mounted || _armed) return;
    _armed = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _skipMotion();
      return;
    }
    _water.forward(from: 0);
  }

  @override
  void dispose() {
    _skyTimer?.cancel();
    _water
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _water,
                builder: (context, _) {
                  return CustomPaint(
                    painter: FarmScenePainter(
                      buildings: widget.buildings,
                      herds: widget.herds,
                      caredToday: widget.caredToday,
                      waterT: _water.value,
                      sky: _sky,
                    ),
                  );
                },
              ),
              if (_emptyYard)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          BalmiCopy.landEmptyField,
                          textAlign: TextAlign.center,
                          style: BalmiTheme.body(
                            size: 14,
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
    required this.sky,
    this.waterT = 0,
  });

  final List<FarmKind> buildings;
  final List<HerdKind> herds;
  final bool caredToday;
  final FarmSkyAppearance sky;
  final double waterT;

  FarmSkyPalette get _palette => sky.palette;

  double get _flash => math.sin(math.pi * waterT.clamp(0.0, 1.0));
  double get _bob => -_flash * 5;

  bool _has(FarmKind kind) => buildings.contains(kind);

  int _shown(HerdKind kind) =>
      herdOnStage(kind, herds.where((h) => h == kind).length);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _sky(canvas, w, h);
    if (_palette.sunOpacity > 0.01) _sun(canvas, w, h);
    if (_palette.moonOpacity > 0.01) _moon(canvas, w, h);
    if (_palette.starOpacity > 0.01) _stars(canvas, w, h);
    if (_palette.cloudOpacity > 0.01) _clouds(canvas, w, h);
    _hills(canvas, w, h);
    _bands(canvas, w, h);
    _path(canvas, w, h);
    _fence(canvas, w, h, ghost: !_has(FarmKind.pastureFence));

    if (_has(FarmKind.barn)) {
      _barn(canvas, Offset(w * 0.18, h * 0.46), w * 0.24);
    }
    if (_has(FarmKind.farmhouse)) {
      _house(canvas, Offset(w * 0.52, h * 0.45), w * 0.22);
    }
    if (_has(FarmKind.villageStore)) {
      _store(canvas, Offset(w * 0.82, h * 0.46), w * 0.2);
    }

    final life = (caredToday || waterT > 0.15) ? 1.0 : 0.62;
    _sheep(canvas, w, h, _shown(HerdKind.sheep), life);
    _chickens(canvas, w, h, _shown(HerdKind.chicken), life);
    _gardens(canvas, w, h, _shown(HerdKind.garden), life);
    _cattle(canvas, w, h, _shown(HerdKind.cattle), life);
    if (waterT > 0) _watering(canvas, w, h);
    if (_palette.nightOverlay > 0.01) _nightOverlay(canvas, w, h);
  }

  Color _dim(Color c) {
    final d = _palette.groundDim.clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF0A1030), c, d)!;
  }

  void _sky(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h * 0.48);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_palette.top, _palette.mid, _palette.bottom],
        ).createShader(rect),
    );
  }

  void _sun(Canvas canvas, double w, double h) {
    final a = _palette.sunOpacity.clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(w * 0.84, h * 0.12),
      h * 0.07,
      Paint()..color = BalmiColors.amber.withValues(alpha: 0.45 * a),
    );
    canvas.drawCircle(
      Offset(w * 0.84, h * 0.12),
      h * 0.042,
      Paint()..color = BalmiColors.amber.withValues(alpha: 0.8 * a),
    );
  }

  void _moon(Canvas canvas, double w, double h) {
    final a = _palette.moonOpacity.clamp(0.0, 1.0);
    final center = Offset(w * 0.84, h * 0.12);
    canvas.drawCircle(
      center,
      h * 0.055,
      Paint()..color = const Color(0xFFA9B8D9).withValues(alpha: 0.4 * a),
    );
    canvas.drawCircle(
      center,
      h * 0.038,
      Paint()..color = const Color(0xFFF0EDE5).withValues(alpha: a),
    );
    canvas.drawCircle(
      Offset(center.dx - h * 0.012, center.dy - h * 0.008),
      h * 0.008,
      Paint()..color = const Color(0xFFD8D5CC).withValues(alpha: 0.55 * a),
    );
  }

  void _stars(Canvas canvas, double w, double h) {
    final a = _palette.starOpacity.clamp(0.0, 1.0);
    for (var i = 0; i < 32; i++) {
      final x = w * (0.08 + ((i * 47) % 100) / 100 * 0.84);
      final y = h * (0.04 + ((i * 19) % 100) / 100 * 0.22);
      final warm = i % 10 == 0;
      final r = warm ? 1.2 : 0.9;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = (warm ? const Color(0xFFFFF6D9) : const Color(0xFFFFFFFF))
              .withValues(alpha: (0.35 + (i % 5) * 0.12) * a),
      );
    }
  }

  void _clouds(Canvas canvas, double w, double h) {
    final a = _palette.cloudOpacity.clamp(0.0, 1.0);
    final puff = Paint()..color = BalmiColors.paper.withValues(alpha: 0.85 * a);
    void cloud(double x, double y, double s) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: s * 2.2, height: s), puff);
      canvas.drawCircle(Offset(x - s * 0.55, y + 1), s * 0.55, puff);
      canvas.drawCircle(Offset(x + s * 0.5, y), s * 0.62, puff);
    }

    cloud(w * 0.22, h * 0.14, 16);
    cloud(w * 0.48, h * 0.1, 12);
  }

  void _nightOverlay(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF0A1030).withValues(alpha: _palette.nightOverlay),
    );
  }

  void _hills(Canvas canvas, double w, double h) {
    final far = Path()
      ..moveTo(0, h * 0.4)
      ..quadraticBezierTo(w * 0.2, h * 0.3, w * 0.46, h * 0.4)
      ..quadraticBezierTo(w * 0.72, h * 0.48, w, h * 0.36)
      ..lineTo(w, h * 0.5)
      ..lineTo(0, h * 0.5)
      ..close();
    canvas.drawPath(far, Paint()..color = _dim(const Color(0xFFC4CDB6)));
    final near = Path()
      ..moveTo(0, h * 0.46)
      ..quadraticBezierTo(w * 0.38, h * 0.38, w * 0.7, h * 0.47)
      ..lineTo(w, h * 0.44)
      ..lineTo(w, h * 0.5)
      ..lineTo(0, h * 0.5)
      ..close();
    canvas.drawPath(near, Paint()..color = _dim(const Color(0xFFA7B592)));
  }

  void _bands(Canvas canvas, double w, double h) {
    final lush = caredToday || _flash > 0.2;
    final farColor = Color.lerp(
      _dim(const Color(0xFF8A9B76)),
      _dim(const Color(0xFFA8C48A)),
      lush ? (0.65 + 0.35 * _flash) : 0,
    )!;
    final far = Rect.fromLTWH(0, h * 0.48, w, h * 0.14);
    canvas.drawRect(far, Paint()..color = farColor);
    final mid = Rect.fromLTWH(0, h * 0.6, w, h * 0.22);
    canvas.drawRect(
      mid,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lush
              ? [
                  _dim(const Color(0xFF8FA37A)),
                  _dim(Color.lerp(BalmiColors.sage, const Color(0xFFA8C48A), _flash)!),
                ]
              : [_dim(BalmiColors.sage), _dim(const Color(0xFF667856))],
        ).createShader(mid),
    );
    final near = Rect.fromLTWH(0, h * 0.8, w, h * 0.2);
    canvas.drawRect(
      near,
      Paint()..color = lush ? _dim(const Color(0xFF738562)) : _dim(const Color(0xFF5E6C4F)),
    );
    final tuft = Paint()
      ..color = const Color(0xFF5C6B4A).withValues(alpha: lush ? 0.7 : 0.45)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 22; i++) {
      final x = w * (0.03 + (i * 0.044) % 0.94);
      final y = h * (0.64 + ((i * 13) % 11) * 0.022);
      canvas.drawLine(Offset(x, y), Offset(x - 2.5, y - 5), tuft);
      canvas.drawLine(Offset(x, y), Offset(x + 2.8, y - 4.5), tuft);
    }
  }

  void _path(Canvas canvas, double w, double h) {
    final dirt = Path()
      ..moveTo(0, h * 0.88)
      ..quadraticBezierTo(w * 0.42, h * 0.74, w, h * 0.82)
      ..lineTo(w, h * 0.9)
      ..quadraticBezierTo(w * 0.42, h * 0.82, 0, h * 0.97)
      ..close();
    canvas.drawPath(dirt, Paint()..color = const Color(0xFFC9A06A));
    canvas.drawPath(
      dirt,
      Paint()
        ..color = const Color(0xFFA9844E).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _fence(Canvas canvas, double w, double h, {required bool ghost}) {
    final a = ghost ? 0.18 : 1.0;
    final rail = Paint()
      ..color = BalmiColors.plum.withValues(alpha: a)
      ..strokeWidth = ghost ? 1.4 : 2.4
      ..strokeCap = StrokeCap.round;
    final post = Paint()..color = BalmiColors.ink.withValues(alpha: a);
    final y1 = h * 0.555;
    final y2 = h * 0.61;
    final end = ghost ? 0.92 : 0.48;
    canvas.drawLine(Offset(w * 0.03, y1), Offset(w * end, y1), rail);
    canvas.drawLine(Offset(w * 0.03, y2), Offset(w * end, y2), rail);
    final n = ghost ? 12 : 8;
    for (var i = 0; i < n; i++) {
      final x = w * (0.04 + i * ((end - 0.04) / (n - 1)));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, h * 0.585), width: 4, height: h * 0.1),
          const Radius.circular(1),
        ),
        post,
      );
    }
  }

  void _shadow(Canvas canvas, Offset c, double rw, double rh) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + rh * 0.85), width: rw, height: rh * 0.28),
      Paint()..color = BalmiColors.ink.withValues(alpha: 0.12),
    );
  }

  void _barn(Canvas canvas, Offset c, double span) {
    _shadow(canvas, c, span * 1.05, span * 0.7);
    final body = Rect.fromCenter(center: c, width: span, height: span * 0.64);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()..color = BalmiColors.plum,
    );
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.top + 10, body.width, 5),
      Paint()..color = BalmiColors.plumLt.withValues(alpha: 0.5),
    );
    final roof = Path()
      ..moveTo(body.left - 8, body.top + 10)
      ..lineTo(body.center.dx, body.top - span * 0.3)
      ..lineTo(body.right + 8, body.top + 10)
      ..close();
    canvas.drawPath(roof, Paint()..color = BalmiColors.ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, body.bottom - 10), width: span * 0.24, height: 20),
        const Radius.circular(2),
      ),
      Paint()..color = BalmiColors.amber,
    );
    final windowGlow = _palette.moonOpacity > 0.45 ? 0.75 : 0.0;
    if (windowGlow > 0) {
      canvas.drawCircle(
        Offset(c.dx, body.center.dy - 2),
        4,
        Paint()..color = BalmiColors.amber.withValues(alpha: windowGlow),
      );
    } else {
      canvas.drawCircle(Offset(c.dx, body.center.dy - 2), 4, Paint()..color = BalmiColors.paper);
    }
  }

  void _house(Canvas canvas, Offset c, double span) {
    _shadow(canvas, c, span * 0.95, span * 0.62);
    final body = Rect.fromCenter(center: c, width: span * 0.88, height: span * 0.56);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()..color = const Color(0xFFF4E8D6),
    );
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.bottom - 8, body.width, 8),
      Paint()..color = const Color(0xFFE4D2B8),
    );
    final roof = Path()
      ..moveTo(body.left - 6, body.top + 7)
      ..lineTo(body.center.dx, body.top - span * 0.24)
      ..lineTo(body.right + 6, body.top + 7)
      ..close();
    canvas.drawPath(roof, Paint()..color = BalmiColors.plum);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.left + 10, body.center.dy - 4, 11, 9),
        const Radius.circular(1),
      ),
      Paint()
        ..color = _palette.moonOpacity > 0.45
            ? BalmiColors.amber.withValues(alpha: 0.7)
            : BalmiColors.amber,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.right - 24, body.bottom - 22, 13, 22),
        const Radius.circular(1),
      ),
      Paint()..color = BalmiColors.ink,
    );
  }

  void _store(Canvas canvas, Offset c, double span) {
    _shadow(canvas, c, span * 1.05, span * 0.55);
    final body = Rect.fromCenter(center: c, width: span, height: span * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(2)),
      Paint()..color = const Color(0xFF5A4638),
    );
    canvas.drawRect(
      Rect.fromLTWH(body.left - 2, body.top - 9, body.width + 4, 11),
      Paint()..color = BalmiColors.amber,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, body.bottom - 9), width: span * 0.3, height: 16),
        const Radius.circular(1),
      ),
      Paint()..color = BalmiColors.paper,
    );
  }

  void _sheep(Canvas canvas, double w, double h, int n, double life) {
    for (var i = 0; i < n; i++) {
      final t = (i + 1) / (n + 1);
      final x = w * (0.07 + t * 0.3 + (i.isOdd ? 0.018 : 0));
      final y = h * (0.7 + (i % 3) * 0.055) + (caredToday ? 0 : 3) + _bob;
      _oneSheep(canvas, Offset(x, y), life);
    }
  }

  void _oneSheep(Canvas canvas, Offset c, double life) {
    final wool = Paint()..color = BalmiColors.paper.withValues(alpha: life);
    final ink = Paint()..color = BalmiColors.ink.withValues(alpha: life);
    final line = Paint()
      ..color = BalmiColors.ink.withValues(alpha: life * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(Offset(c.dx - 5, c.dy), 7.2, wool);
    canvas.drawCircle(Offset(c.dx + 4, c.dy + 1), 6.6, wool);
    canvas.drawCircle(Offset(c.dx, c.dy - 5), 6.2, wool);
    canvas.drawCircle(Offset(c.dx - 5, c.dy), 7.2, line);
    canvas.drawCircle(Offset(c.dx + 4, c.dy + 1), 6.6, line);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx + 10, c.dy - 2), width: 8, height: 7),
      ink,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx + 12, c.dy - 6), width: 3.2, height: 3.8),
      wool,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx + 8, c.dy - 6), width: 3.2, height: 3.8),
      wool,
    );
    final legs = Paint()
      ..color = BalmiColors.ink.withValues(alpha: life)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final dx in [-5.0, -1.5, 2.5, 6.0]) {
      canvas.drawLine(Offset(c.dx + dx, c.dy + 5), Offset(c.dx + dx, c.dy + 12), legs);
    }
  }

  void _chickens(Canvas canvas, double w, double h, int n, double life) {
    for (var i = 0; i < n; i++) {
      final x = w * (0.18 + (i % 4) * 0.05);
      final y = h * (0.58 + (i ~/ 4) * 0.055) + (caredToday ? 0 : 2) + _bob;
      _oneChicken(canvas, Offset(x, y), life);
    }
  }

  void _oneChicken(Canvas canvas, Offset c, double life) {
    final body = Paint()..color = BalmiColors.amber.withValues(alpha: life);
    final ink = Paint()..color = BalmiColors.ink.withValues(alpha: life);
    final comb = Paint()..color = BalmiColors.plum.withValues(alpha: life);
    canvas.drawOval(Rect.fromCenter(center: c, width: 13, height: 9), body);
    final tail = Path()
      ..moveTo(c.dx - 5, c.dy)
      ..quadraticBezierTo(c.dx - 12, c.dy - 6, c.dx - 6, c.dy - 8)
      ..quadraticBezierTo(c.dx - 8, c.dy - 1, c.dx - 4, c.dy + 1)
      ..close();
    canvas.drawPath(tail, body);
    canvas.drawCircle(Offset(c.dx + 5, c.dy - 3), 3.6, body);
    canvas.drawCircle(Offset(c.dx + 4.2, c.dy - 7), 1.5, comb);
    canvas.drawCircle(Offset(c.dx + 6, c.dy - 6.6), 1.3, comb);
    canvas.drawCircle(Offset(c.dx + 6.2, c.dy - 3.2), 0.7, ink);
    final beak = Path()
      ..moveTo(c.dx + 8, c.dy - 3)
      ..lineTo(c.dx + 12, c.dy - 2)
      ..lineTo(c.dx + 8, c.dy - 1)
      ..close();
    canvas.drawPath(beak, comb);
    canvas.drawLine(
      Offset(c.dx - 1, c.dy + 4),
      Offset(c.dx - 1, c.dy + 9),
      Paint()
        ..color = BalmiColors.ink.withValues(alpha: life)
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(
      Offset(c.dx + 2, c.dy + 4),
      Offset(c.dx + 2, c.dy + 9),
      Paint()
        ..color = BalmiColors.ink.withValues(alpha: life)
        ..strokeWidth = 1.1,
    );
  }

  void _gardens(Canvas canvas, double w, double h, int n, double life) {
    for (var i = 0; i < n; i++) {
      final left = w * (0.44 + (i % 2) * 0.13);
      final top = h * (0.66 + (i ~/ 2) * 0.09) + _bob;
      final bed = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w * 0.11, h * 0.075),
        const Radius.circular(4),
      );
      canvas.drawRRect(bed, Paint()..color = const Color(0xFF8B6A3E).withValues(alpha: life));
      canvas.drawRRect(
        bed,
        Paint()
          ..color = const Color(0xFF6A4E2A).withValues(alpha: life)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      for (var r = 0; r < 3; r++) {
        for (var d = 0; d < 4; d++) {
          final p = Offset(left + 8 + d * 10.0, top + 6 + r * 6.5);
          canvas.drawLine(
            p,
            Offset(p.dx, p.dy - 5),
            Paint()
              ..color = BalmiColors.sage.withValues(alpha: life)
              ..strokeWidth = 1.4
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawCircle(
            Offset(p.dx, p.dy - 6),
            2.4,
            Paint()..color = const Color(0xFF5E734C).withValues(alpha: life),
          );
        }
      }
    }
  }

  void _cattle(Canvas canvas, double w, double h, int n, double life) {
    for (var i = 0; i < n; i++) {
      final x = w * (0.68 + i * 0.1);
      final y = h * (0.72 + (i.isOdd ? 0.05 : 0)) + (caredToday ? 0 : 3) + _bob;
      _oneCow(canvas, Offset(x, y), life);
    }
  }

  void _oneCow(Canvas canvas, Offset c, double life) {
    final hide = Paint()..color = const Color(0xFF4A342C).withValues(alpha: life);
    final paper = Paint()..color = BalmiColors.paper.withValues(alpha: life);
    canvas.drawOval(Rect.fromCenter(center: c, width: 34, height: 18), hide);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx - 6, c.dy - 6), width: 14, height: 10),
      hide,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx + 14, c.dy - 3), width: 14, height: 11),
      hide,
    );
    canvas.drawCircle(Offset(c.dx + 18, c.dy - 1), 2.2, paper);
    final horn = Paint()
      ..color = BalmiColors.paper.withValues(alpha: life)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx + 12, c.dy - 8), Offset(c.dx + 9, c.dy - 14), horn);
    canvas.drawLine(Offset(c.dx + 16, c.dy - 8), Offset(c.dx + 20, c.dy - 14), horn);
    final legs = Paint()
      ..color = BalmiColors.ink.withValues(alpha: life)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final dx in [-10.0, -4.0, 5.0, 11.0]) {
      canvas.drawLine(Offset(c.dx + dx, c.dy + 7), Offset(c.dx + dx, c.dy + 16), legs);
    }
    canvas.drawLine(
      Offset(c.dx - 16, c.dy + 2),
      Offset(c.dx - 20, c.dy + 8),
      Paint()
        ..color = BalmiColors.ink.withValues(alpha: life)
        ..strokeWidth = 1.4,
    );
  }

  void _watering(Canvas canvas, double w, double h) {
    final t = waterT.clamp(0.0, 1.0);
    if (t <= 0) return;
    final pivot = Offset(w * 0.78, h * 0.34);
    final tilt = -0.42 * Curves.easeInOut.transform(t);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(tilt);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-18, -10, 28, 18),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, Paint()..color = BalmiColors.plum);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-22, -6, 8, 10),
        const Radius.circular(3),
      ),
      Paint()..color = BalmiColors.plum,
    );
    canvas.drawArc(
      const Rect.fromLTWH(-4, -22, 22, 20),
      3.4,
      2.4,
      false,
      Paint()
        ..color = BalmiColors.sage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    final spout = Offset(
      pivot.dx - 22 * math.cos(tilt) + 4 * math.sin(tilt),
      pivot.dy - 22 * math.sin(tilt) - 4 * math.cos(tilt),
    );
    final drop = Paint()..color = BalmiColors.sage;
    final paper = Paint()..color = BalmiColors.paper.withValues(alpha: 0.85);
    for (var i = 0; i < 7; i++) {
      final local = ((t * 1.35) - i * 0.09).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final dest = Offset(w * (0.18 + i * 0.07), h * 0.72);
      final x = spout.dx + (dest.dx - spout.dx) * local;
      final y = spout.dy + (dest.dy - spout.dy) * local * local + local * 8;
      final a = (1 - local) * 0.95;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 5, height: 7),
        Paint()..color = BalmiColors.sage.withValues(alpha: a),
      );
      canvas.drawCircle(Offset(x - 0.8, y - 1.2), 1.1, paper);
    }
    canvas.drawCircle(spout, 1.5, drop);
  }

  @override
  bool shouldRepaint(covariant FarmScenePainter old) {
    return old.caredToday != caredToday ||
        old.waterT != waterT ||
        old.sky.phase != sky.phase ||
        old.sky.palette.top != sky.palette.top ||
        old.sky.palette.sunOpacity != sky.palette.sunOpacity ||
        old.sky.palette.moonOpacity != sky.palette.moonOpacity ||
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
