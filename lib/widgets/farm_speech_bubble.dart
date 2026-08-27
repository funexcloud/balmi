import 'package:flutter/material.dart';

import '../core/theme.dart';

/// In-process memory: once a caption sequence is finished, it stays hidden
/// until the tip lines change (or the process restarts).
abstract final class FarmSpeechBubbleSession {
  static final Set<String> _dismissedKeys = <String>{};

  static bool isDismissed(List<String> lines) =>
      lines.isNotEmpty && _dismissedKeys.contains(_key(lines));

  static void markDismissed(List<String> lines) {
    if (lines.isEmpty) return;
    _dismissedKeys.add(_key(lines));
  }

  /// Test-only reset.
  @visibleForTesting
  static void clearForTest() => _dismissedKeys.clear();

  static String _key(List<String> lines) => lines.join('\u001f');
}

/// Soft farm caption bubble: one sentence at a time, tap to advance;
/// hides after the last tip for the rest of the session.
class FarmSpeechBubble extends StatefulWidget {
  const FarmSpeechBubble({
    super.key,
    required this.lines,
    this.onAdvance,
    this.onDismissed,
  });

  final List<String> lines;
  final VoidCallback? onAdvance;
  final VoidCallback? onDismissed;

  @override
  State<FarmSpeechBubble> createState() => _FarmSpeechBubbleState();
}

class _FarmSpeechBubbleState extends State<FarmSpeechBubble> {
  var _index = 0;
  var _dismissed = false;

  @override
  void initState() {
    super.initState();
    _dismissed = FarmSpeechBubbleSession.isDismissed(widget.lines);
  }

  @override
  void didUpdateWidget(covariant FarmSpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dismissed) return;
    if (oldWidget.lines.length != widget.lines.length ||
        !_sameLines(oldWidget.lines, widget.lines)) {
      _index = 0;
      _dismissed = FarmSpeechBubbleSession.isDismissed(widget.lines);
    } else if (!_dismissed && _index >= widget.lines.length) {
      _index = 0;
    }
  }

  bool _sameLines(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _advance() {
    if (_dismissed || widget.lines.isEmpty) return;
    final last = _index >= widget.lines.length - 1;
    if (last) {
      FarmSpeechBubbleSession.markDismissed(widget.lines);
      setState(() => _dismissed = true);
      widget.onAdvance?.call();
      widget.onDismissed?.call();
      return;
    }
    setState(() => _index += 1);
    widget.onAdvance?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty || _dismissed) return const SizedBox.shrink();
    final line = widget.lines[_index.clamp(0, widget.lines.length - 1)];
    final multi = widget.lines.length > 1;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Soft translucent glass fill that blends with day/night farm sky.
    const fill = Color(0xF0FAF6F0); // ~94% opaque warm paper glass
    const edge = Color(0x33C4B8A8); // subtle soft border
    const inkSoft = Color(0xEE2D251E); // crisp dark brown text

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Semantics(
        button: true,
        label: line,
        hint: multi && _index < widget.lines.length - 1 ? '다음 안내' : '안내 닫기',
        excludeSemantics: true,
        child: AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            if (reduceMotion) return child;
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: _BubbleBody(
            key: ValueKey<String>('$line-$_index'),
            text: line,
            showHint: true,
            fill: fill,
            edge: edge,
            ink: inkSoft,
          ),
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    super.key,
    required this.text,
    required this.showHint,
    required this.fill,
    required this.edge,
    required this.ink,
  });

  final String text;
  final bool showHint;
  final Color fill;
  final Color edge;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x18000000),
            blurRadius: 14,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0x0C000000),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w600,
              color: ink,
              height: 1.38,
            ),
          ),
          if (showHint) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: BalmiColors.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '탭',
                    style: BalmiTheme.body(
                      size: 10,
                      weight: FontWeight.w700,
                      color: BalmiColors.sub.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 12,
                    color: BalmiColors.sub.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color, required this.border});

  final Color color;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    // Rounded-ish soft triangle that sits under the bubble.
    final path = Path()
      ..moveTo(size.width * 0.28, 0.5)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.35,
        size.width * 0.5,
        size.height,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.35,
        size.width * 0.72,
        0.5,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round,
    );
    // Cover the top stroke so the tail joins the bubble cleanly.
    canvas.drawLine(
      Offset(size.width * 0.3, 0.5),
      Offset(size.width * 0.7, 0.5),
      Paint()
        ..color = color
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.color != color || old.border != border;
}
