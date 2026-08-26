import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Soft farm caption bubble: one sentence at a time, tap to advance.
class FarmSpeechBubble extends StatefulWidget {
  const FarmSpeechBubble({
    super.key,
    required this.lines,
    this.onAdvance,
  });

  final List<String> lines;
  final VoidCallback? onAdvance;

  @override
  State<FarmSpeechBubble> createState() => _FarmSpeechBubbleState();
}

class _FarmSpeechBubbleState extends State<FarmSpeechBubble> {
  var _index = 0;

  @override
  void didUpdateWidget(covariant FarmSpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.length != widget.lines.length ||
        !_sameLines(oldWidget.lines, widget.lines)) {
      _index = 0;
    } else if (_index >= widget.lines.length) {
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
    if (widget.lines.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.lines.length);
    widget.onAdvance?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();
    final line = widget.lines[_index.clamp(0, widget.lines.length - 1)];
    final multi = widget.lines.length > 1;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Soft cream fill that blends with day/night farm sky.
    const fill = Color(0xE6FFF8EE); // ~90% opaque warm paper
    const edge = Color(0x66C4B8A8); // soft taupe border
    const inkSoft = Color(0xCC3D342C); // muted brown text

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Semantics(
        button: multi,
        label: line,
        hint: multi ? '다음 안내' : null,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
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
                showHint: multi,
                fill: fill,
                edge: edge,
                ink: inkSoft,
              ),
            ),
            CustomPaint(
              size: const Size(16, 9),
              painter: _BubbleTailPainter(
                color: fill,
                border: edge,
              ),
            ),
          ],
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
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: BalmiColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              height: 1.35,
            ),
          ),
          if (showHint) ...[
            const SizedBox(height: 3),
            Text(
              '탭',
              style: BalmiTheme.body(
                size: 10,
                weight: FontWeight.w500,
                color: BalmiColors.sub.withValues(alpha: 0.7),
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
