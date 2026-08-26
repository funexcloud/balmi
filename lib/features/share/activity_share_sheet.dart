import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../domain/engines/activity_share.dart';
import '../../widgets/balmi_wordmark.dart';

Future<void> openActivityShareSheet(
  BuildContext context, {
  required String sessionId,
  required String activityLabel,
  required double distanceM,
  required Duration duration,
  required int steps,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BalmiColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return ActivityShareSheet(
        sessionId: sessionId,
        activityLabel: activityLabel,
        distanceM: distanceM,
        duration: duration,
        steps: steps,
      );
    },
  );
}

class ActivityShareSheet extends StatefulWidget {
  const ActivityShareSheet({
    super.key,
    required this.sessionId,
    required this.activityLabel,
    required this.distanceM,
    required this.duration,
    required this.steps,
  });

  final String sessionId;
  final String activityLabel;
  final double distanceM;
  final Duration duration;
  final int steps;

  @override
  State<ActivityShareSheet> createState() => _ActivityShareSheetState();
}

class _ActivityShareSheetState extends State<ActivityShareSheet> {
  ActivityShareStyle _style = ActivityShareStyle.record;
  bool _hideStartEnd = true;

  ActivityShareSummary get _summary => buildActivityShareSummary(
        sessionId: widget.sessionId,
        style: _style,
        activityLabel: widget.activityLabel,
        distanceM: widget.distanceM,
        duration: widget.duration,
        steps: widget.steps,
        hideStartEnd: _hideStartEnd,
      );

  Future<void> _share() async {
    final text = buildActivityShareText(_summary);
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BalmiColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            BalmiCopy.shareTitle,
            style: BalmiTheme.body(size: 18, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            BalmiCopy.shareSubtitle,
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
          ),
          const SizedBox(height: 16),
          _ShareCardPreview(summary: summary),
          const SizedBox(height: 16),
          Text(
            BalmiCopy.shareStyleLabel,
            style: BalmiTheme.tracked(size: 10, color: BalmiColors.sub),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in ActivityShareStyle.values)
                _StyleChip(
                  label: _styleLabel(style),
                  selected: _style == style,
                  enabled: style.isAvailable,
                  onTap: style.isAvailable
                      ? () => setState(() => _style = style)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              BalmiCopy.shareHideStartEnd,
              style: BalmiTheme.body(size: 14, weight: FontWeight.w700),
            ),
            subtitle: Text(
              BalmiCopy.shareHideStartEndHint,
              style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
            ),
            value: _hideStartEnd,
            activeThumbColor: BalmiColors.potato,
            onChanged: (v) => setState(() => _hideStartEnd = v),
          ),
          const SizedBox(height: 8),
          Text(
            BalmiCopy.shareDeepLinkStubHint,
            style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _share,
            style: FilledButton.styleFrom(
              backgroundColor: BalmiColors.potato,
              foregroundColor: BalmiColors.paper,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              BalmiCopy.shareAction,
              style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String _styleLabel(ActivityShareStyle style) => switch (style) {
        ActivityShareStyle.map => BalmiCopy.shareStyleMap,
        ActivityShareStyle.record => BalmiCopy.shareStyleRecord,
        ActivityShareStyle.minimal => BalmiCopy.shareStyleMinimal,
        ActivityShareStyle.vasa => BalmiCopy.shareStyleVasa,
      };
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = !enabled
        ? BalmiColors.mist
        : selected
            ? BalmiColors.potato
            : BalmiColors.mist;
    final fg = !enabled
        ? BalmiColors.sub
        : selected
            ? BalmiColors.paper
            : BalmiColors.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w800,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareCardPreview extends StatelessWidget {
  const _ShareCardPreview({required this.summary});

  final ActivityShareSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F3), Color(0xFFF3F3F3)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BalmiColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BalmiWordmark(height: 22),
          const SizedBox(height: 14),
          Text(
            summary.headline,
            style: BalmiTheme.body(size: 17, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            [
              formatShareElapsed(summary.duration),
              if (summary.steps > 0) '${formatShareSteps(summary.steps)}걸음',
              if (summary.avgPaceLabel != null)
                '페이스 ${summary.avgPaceLabel}',
            ].join(' · '),
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
          ),
          if (summary.includeMap) ...[
            const SizedBox(height: 10),
            Text(
              summary.hideStartEnd
                  ? BalmiCopy.shareMapPrivacyOn
                  : BalmiCopy.shareMapPrivacyOff,
              style: BalmiTheme.body(size: 12, color: BalmiColors.plum),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            summary.tagline,
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w700,
              color: BalmiColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
