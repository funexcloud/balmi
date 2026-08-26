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

/// Soft speech bubble: one sentence at a time, tap to advance; hides after the last.
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
    final fill = BalmiColors.paper.withValues(alpha: 0.82);
    final edge = BalmiColors.line.withValues(alpha: 0.55);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Semantics(
        button: true,
        label: line,
        hint: multi && _index < widget.lines.length - 1 ? '다음 안내' : '안내 닫기',
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
                showHint: true,
                fill: fill,
                border: edge,
              ),
            ),
            CustomPaint(
              size: const Size(18, 10),
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
    required this.border,
  });

  final String text;
  final bool showHint;
  final Color fill;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
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
              weight: FontWeight.w700,
              color: BalmiColors.ink.withValues(alpha: 0.88),
            ),
          ),
          if (showHint) ...[
            const SizedBox(height: 4),
            Text(
              '탭',
              style: BalmiTheme.body(
                size: 10,
                color: BalmiColors.sub.withValues(alpha: 0.85),
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
