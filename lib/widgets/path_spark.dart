import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../core/theme.dart';
import '../domain/engines/distance.dart';

/// Segment lengths along a trail — a path pulse, not an elevation clone.
List<double> sparkFromTrail(List<LatLng> points, {int cap = 80}) {
  if (points.length < 2) return const [];
  final start = points.length > cap ? points.length - cap : 0;
  final out = <double>[];
  for (var i = start + 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    out.add(
      haversineMeters(
        lat1: a.latitude,
        lon1: a.longitude,
        lat2: b.latitude,
        lon2: b.longitude,
      ),
    );
  }
  return out;
}

class PathSpark extends StatelessWidget {
  const PathSpark({super.key, required this.values, this.height = 36});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(values),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) {
      final mid = size.height / 2;
      canvas.drawLine(
        Offset(0, mid),
        Offset(size.width, mid),
        Paint()
          ..color = BalmiColors.line
          ..strokeWidth = 1.5,
      );
      return;
    }
    var minV = values.first;
    var maxV = values.first;
    for (final v in values) {
      minV = math.min(minV, v);
      maxV = math.max(maxV, v);
    }
    final span = (maxV - minV).abs() < 0.01 ? 1.0 : maxV - minV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final t = (values[i] - minV) / span;
      final y = size.height - t * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        // Path pulse shares Sweet Potato with map GPS tracks / heartbeat.
        ..color = BalmiColors.trackPath
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) {
    if (old.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (old.values[i] != values[i]) return true;
    }
    return false;
  }
}
