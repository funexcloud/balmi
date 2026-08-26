import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../widgets/balmi_wordmark.dart';
import '../../widgets/safe_cta.dart';
import 'onboarding_path_visual.dart';

/// First-run story: MOVE → OFFLINE → RECOVERY → PROMISE.
/// OS permission dialogs are **not** shown here — recording requests them later.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _lastIndex = BalmiCopy.onboardingPageCount - 1;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < _lastIndex) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8F3),
              BalmiColors.paper,
              Color(0xFFF4F7F2),
            ],
            stops: [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BalmiWordmark(height: 26),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: const [
                    _MovePage(),
                    _OfflinePage(),
                    _RecoveryPage(),
                    _PromisePage(),
                  ],
                ),
              ),
              _PageDots(index: _index, count: BalmiCopy.onboardingPageCount),
              SafePrimaryButton(
                label: _index < _lastIndex
                    ? BalmiCopy.onboardingNext
                    : BalmiCopy.onboardingStart,
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              active ? '●' : '○',
              style: TextStyle(
                fontSize: 11,
                height: 1,
                color: active ? BalmiColors.potatoDk : BalmiColors.sub,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StoryHeader extends StatelessWidget {
  const _StoryHeader({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BalmiTheme.body(size: 26, weight: FontWeight.w800, height: 1.28),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: BalmiTheme.body(
            size: 15,
            weight: FontWeight.w600,
            height: 1.55,
            color: BalmiColors.ink.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }
}

class _MovePage extends StatefulWidget {
  const _MovePage();

  @override
  State<_MovePage> createState() => _MovePageState();
}

class _MovePageState extends State<_MovePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  static const _chips = [
    BalmiCopy.onboardingMoveWalk,
    BalmiCopy.onboardingMoveRun,
    BalmiCopy.onboardingMoveTrack,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StoryHeader(
            title: BalmiCopy.onboardingMoveTitle,
            body: BalmiCopy.onboardingMoveBody,
          ),
          const SizedBox(height: 22),
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_ctrl.value);
                final chipIndex = (_ctrl.value * _chips.length)
                    .floor()
                    .clamp(0, _chips.length - 1);
                return Column(
                  children: [
                    OnboardingPathVisual(
                      progress: t,
                      variant: OnboardingPathVariant.single,
                      height: 210,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _chips.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '→',
                                style: BalmiTheme.body(
                                  size: 13,
                                  color: BalmiColors.sub,
                                ),
                              ),
                            ),
                          _ModeChip(label: _chips[i], active: i == chipIndex),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? BalmiColors.potato.withValues(alpha: 0.14)
            : BalmiColors.mist,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? BalmiColors.potato.withValues(alpha: 0.45)
              : BalmiColors.line,
        ),
      ),
      child: Text(
        label,
        style: BalmiTheme.body(
          size: 12,
          weight: FontWeight.w700,
          color: active ? BalmiColors.potatoDk : BalmiColors.ink,
        ),
      ),
    );
  }
}

class _OfflinePage extends StatefulWidget {
  const _OfflinePage();

  @override
  State<_OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<_OfflinePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StoryHeader(
            title: BalmiCopy.onboardingOfflineTitle,
            body: BalmiCopy.onboardingOfflineBody,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                // Path keeps growing even as network drops (5G → weak → none).
                final pathT = (0.35 + _ctrl.value * 0.65).clamp(0.0, 1.0);
                final phase = _ctrl.value < 0.33
                    ? 0
                    : _ctrl.value < 0.66
                        ? 1
                        : 2;
                final netLabel = switch (phase) {
                  0 => BalmiCopy.onboardingNet5g,
                  1 => BalmiCopy.onboardingNetWeak,
                  _ => BalmiCopy.onboardingNetNone,
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _StatusPill(
                          label: BalmiCopy.onboardingGpsOk,
                          tone: BalmiColors.sage,
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: netLabel,
                          tone: phase == 0
                              ? BalmiColors.sage
                              : phase == 1
                                  ? BalmiColors.amber
                                  : BalmiColors.plum,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OnboardingPathVisual(
                      progress: pathT,
                      variant: OnboardingPathVariant.offline,
                      networkPhase: phase,
                      height: 200,
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _StatusPill(
                        label: BalmiCopy.onboardingOfflineBadge,
                        tone: BalmiColors.potato,
                        filled: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.tone,
    this.filled = false,
  });

  final String label;
  final Color tone;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? tone.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: BalmiTheme.body(
          size: 12,
          weight: FontWeight.w700,
          color: tone == BalmiColors.potato ? BalmiColors.potatoDk : tone,
        ),
      ),
    );
  }
}

class _RecoveryPage extends StatefulWidget {
  const _RecoveryPage();

  @override
  State<_RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<_RecoveryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StoryHeader(
            title: BalmiCopy.onboardingRecoveryTitle,
            body: BalmiCopy.onboardingRecoveryBody,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _ctrl.value;
                // 0–0.28 recording, 0.28–0.45 gone, 0.45–0.62 relaunch, 0.62–1 recovered
                final phase = t < 0.28
                    ? 0
                    : t < 0.45
                        ? 1
                        : t < 0.62
                            ? 2
                            : 3;
                final pathT = phase == 0
                    ? (t / 0.28).clamp(0.0, 1.0)
                    : phase == 1
                        ? 0.0
                        : phase == 2
                            ? 0.15
                            : Curves.easeOutCubic.transform(
                                ((t - 0.62) / 0.38).clamp(0.0, 1.0),
                              );
                final dimmed = phase == 1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: phase == 1 ? 0.15 : 1,
                      child: OnboardingPathVisual(
                        progress: pathT,
                        variant: phase >= 3
                            ? OnboardingPathVariant.recovered
                            : OnboardingPathVariant.single,
                        dimmed: dimmed,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: Text(
                        phase <= 1
                            ? BalmiCopy.onboardingRecoveryDistance
                            : phase == 2
                                ? BalmiCopy.appName
                                : BalmiCopy.onboardingRecoveryRestored,
                        key: ValueKey(phase),
                        textAlign: TextAlign.center,
                        style: BalmiTheme.num(
                          size: phase >= 3 ? 20 : 28,
                          weight: FontWeight.w800,
                          color: phase >= 3
                              ? BalmiColors.potatoDk
                              : BalmiColors.ink,
                        ),
                      ),
                    ),
                    if (phase >= 3) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatusPill(
                            label: BalmiCopy.onboardingRecoveryBadge,
                            tone: BalmiColors.sage,
                            filled: true,
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(
                            label: BalmiCopy.onboardingRecoveryBadgeEn,
                            tone: BalmiColors.sage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        BalmiCopy.onboardingRecoveryDistance,
                        textAlign: TextAlign.center,
                        style: BalmiTheme.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: BalmiColors.sub,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PromisePage extends StatefulWidget {
  const _PromisePage();

  @override
  State<_PromisePage> createState() => _PromisePageState();
}

class _PromisePageState extends State<_PromisePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StoryHeader(
            title: BalmiCopy.onboardingPromiseTitle,
            body: BalmiCopy.onboardingPromiseBody,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_ctrl.value);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnboardingPathVisual(
                      progress: t,
                      variant: OnboardingPathVariant.merged,
                      height: 168,
                    ),
                    const SizedBox(height: 18),
                    const BalmiWordmark(height: 36),
                    const SizedBox(height: 12),
                    Text(
                      BalmiCopy.slogan,
                      style: BalmiTheme.body(
                        size: 15,
                        weight: FontWeight.w800,
                        height: 1.4,
                        color: BalmiColors.potatoDk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      BalmiCopy.subcopy,
                      style: BalmiTheme.body(
                        size: 13,
                        color: BalmiColors.sub,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> markOnboardingDone(SessionRepository repo) {
  return repo.putKv('onboarding_done', '1');
}

Future<bool> isOnboardingDone(SessionRepository repo) async {
  return (await repo.getKv('onboarding_done')) == '1';
}
