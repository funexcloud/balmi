import 'package:flutter/material.dart';

import '../core/copy.dart';
import '../core/theme.dart';
import '../data/recording/recording_snapshot.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.child,
    this.on = false,
    this.onColor = BalmiColors.sage,
  });

  final Widget child;
  final bool on;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: on ? onColor : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: on ? onColor : BalmiColors.line),
      ),
      child: DefaultTextStyle(
        style: BalmiTheme.body(
          size: 12,
          weight: FontWeight.w600,
          color: on ? Colors.white : BalmiColors.ink,
        ),
        child: child,
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = BalmiColors.sage, this.pulse = true});

  final Color color;
  final bool pulse;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat(reverse: true);
    }
    if (!widget.pulse) {
      _c
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.pulse
          ? Tween<double>(begin: 0.35, end: 1).animate(_c)
          : const AlwaysStoppedAnimation(1),
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class RecordingStatusChips extends StatelessWidget {
  const RecordingStatusChips({
    super.key,
    required this.snapshot,
    this.waiting = false,
  });

  final RecordingSnapshot? snapshot;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final points = s?.pointCount ?? 0;
    final strength = s?.gpsStrength ?? 'none';
    final pulse = points == 0 || strength == 'strong' || strength == 'ok';
    final acc = s?.hAccM;

    return Semantics(
      label: waiting && points == 0
          ? '${BalmiCopy.gps} ${BalmiCopy.waitingGpsShort}'
          : acc == null
              ? '${BalmiCopy.gps} ${BalmiCopy.gpsStrength(strength)}'
              : '${BalmiCopy.gps} ${BalmiCopy.gpsStrength(strength)} ±${acc.round()}m',
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulseDot(pulse: pulse),
            GpsSignalBars(
              strength: waiting && points == 0 ? 'none' : strength,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wifi-style GPS strength. Accuracy stays in semantics, not chrome text.
class GpsSignalBars extends StatelessWidget {
  const GpsSignalBars({super.key, required this.strength});

  final String strength;

  int get _filled => switch (strength) {
        'strong' => 4,
        'ok' => 3,
        'weak' => 2,
        'poor' => 1,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: CustomPaint(
        painter: _GpsBarsPainter(filled: _filled),
      ),
    );
  }
}

class _GpsBarsPainter extends CustomPainter {
  const _GpsBarsPainter({required this.filled});

  final int filled;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final gap = size.width * 0.12;
    final w = (size.width - gap * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      final h = size.height * ((i + 1) / n);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (w + gap), size.height - h, w, h),
        const Radius.circular(1.6),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = i < filled ? BalmiColors.ink : BalmiColors.line
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GpsBarsPainter old) => old.filled != filled;
}

class SportPill extends StatelessWidget {
  const SportPill({super.key, required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: running ? BalmiCopy.run : BalmiCopy.walk,
      child: Icon(
        running ? Icons.directions_run : Icons.directions_walk,
        size: 22,
        color: BalmiColors.ink,
      ),
    );
  }
}

class LiveStat extends StatelessWidget {
  const LiveStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: BalmiColors.sub),
          const SizedBox(height: 2),
          Text(value, style: BalmiTheme.num(size: 21)),
        ],
      ),
    );
  }
}
