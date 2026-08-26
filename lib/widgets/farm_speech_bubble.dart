import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Comic-style speech bubble: one sentence at a time, tap to advance.
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
                  begin: const Offset(0, 0.18),
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
              ),
            ),
            CustomPaint(
              size: const Size(18, 10),
              painter: _BubbleTailPainter(
                color: BalmiColors.paper,
                border: BalmiColors.line,
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
  });

  final String text;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: BalmiColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BalmiColors.line),
        boxShadow: [
          BoxShadow(
            color: BalmiColors.ink.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
              weight: FontWeight.w800,
              color: BalmiColors.ink,
            ),
          ),
          if (showHint) ...[
            const SizedBox(height: 4),
            Text(
              '탭',
              style: BalmiTheme.body(size: 10, color: BalmiColors.sub),
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
    final path = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.8, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Cover the top stroke so the tail joins the bubble cleanly.
    canvas.drawLine(
      Offset(size.width * 0.22, 0),
      Offset(size.width * 0.78, 0),
      Paint()
        ..color = color
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.color != color || old.border != border;
}
