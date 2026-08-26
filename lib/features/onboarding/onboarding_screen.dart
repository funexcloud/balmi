import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/location/recording_permissions.dart';
import '../../data/oem/battery_optimization.dart';
import '../../data/repositories/session_repository.dart';
import '../../widgets/balmi_wordmark.dart';
import '../../widgets/safe_cta.dart';

/// First-run onboarding: one 4-beat durability story, then permission gate.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;
  bool _ignoring = false;
  String? _permHint;

  static const _lastIndex = BalmiCopy.onboardingPageCount - 1;

  @override
  void initState() {
    super.initState();
    _loadOem();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _loadOem() async {
    final ignoring = await OemBattery.isIgnoringOptimizations();
    if (!mounted) return;
    setState(() => _ignoring = ignoring);
  }

  Future<bool> _locationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always ||
        p == LocationPermission.whileInUse;
  }

  Future<void> _requestRecordingPerms() async {
    final denied = await RecordingPermissions.ensure();
    if (denied != null) {
      if (!mounted) return;
      setState(() => _permHint = denied);
      return;
    }
    final whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) {
      if (!mounted) return;
      setState(() => _permHint = BalmiCopy.locationDenied);
      return;
    }
    await Permission.locationAlways.request();
    await Permission.notification.request();
  }

  Future<void> _next() async {
    setState(() => _permHint = null);
    if (_index < _lastIndex) {
      // Request location before the final promise screen so "시작하기" can finish.
      if (_index == _lastIndex - 1) {
        await _requestRecordingPerms();
        if (_permHint != null) return;
      }
      await _page.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!await _locationReady()) {
      await _requestRecordingPerms();
      if (!await _locationReady()) {
        if (!mounted) return;
        setState(() => _permHint = BalmiCopy.permsRequired);
        return;
      }
    }
    if (!_ignoring) {
      await OemBattery.requestIgnore();
      await _loadOem();
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
              Color(0xFFF7F3EF),
            ],
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    const BalmiWordmark(height: 28),
                    const Spacer(),
                    Text(
                      '${_index + 1} / ${BalmiCopy.onboardingPageCount}',
                      style: BalmiTheme.tracked(
                        size: 11,
                        color: BalmiColors.sub,
                        trackingEm: 0.12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  onPageChanged: (i) => setState(() {
                    _index = i;
                    _permHint = null;
                  }),
                  children: const [
                    _StoryPage(
                      kicker: '기록의 시작',
                      title: BalmiCopy.onboardingStory1Title,
                      body: BalmiCopy.onboardingStory1Body,
                      tags: BalmiCopy.onboardingStory1Tags,
                    ),
                    _StoryPage(
                      kicker: '오프라인 기록',
                      title: BalmiCopy.onboardingStory2Title,
                      body: BalmiCopy.onboardingStory2Body,
                      badge: BalmiCopy.onboardingStory2Badge,
                    ),
                    _StoryPage(
                      kicker: '기록 복구',
                      title: BalmiCopy.onboardingStory3Title,
                      body: BalmiCopy.onboardingStory3Body,
                      badge: BalmiCopy.onboardingStory3Badge,
                    ),
                    _PromisePage(),
                  ],
                ),
              ),
              _PageDots(index: _index, count: BalmiCopy.onboardingPageCount),
              if (_permHint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    _permHint!,
                    style: BalmiTheme.body(
                      size: 13,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SafePrimaryButton(
                label: _index < _lastIndex
                    ? BalmiCopy.continueLabel
                    : BalmiCopy.done,
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
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: active ? 18 : 6,
            decoration: BoxDecoration(
              color: active ? BalmiColors.potato : BalmiColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.kicker,
    required this.title,
    required this.body,
    this.badge,
    this.tags,
  });

  final String kicker;
  final String title;
  final String body;
  final String? badge;
  final String? tags;

  @override
  Widget build(BuildContext context) {
    return _AnimatedStoryPane(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kicker,
              style: BalmiTheme.tracked(
                size: 11,
                color: BalmiColors.potatoDk,
                trackingEm: 0.14,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: BalmiTheme.body(size: 26, weight: FontWeight.w800, height: 1.28),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: BalmiTheme.body(
                size: 15,
                weight: FontWeight.w600,
                height: 1.55,
                color: BalmiColors.ink.withValues(alpha: 0.88),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 28),
              _Badge(label: badge!),
            ],
            if (tags != null) ...[
              const SizedBox(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags!
                    .split(' · ')
                    .map((t) => _TagChip(label: t.trim()))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PromisePage extends StatelessWidget {
  const _PromisePage();

  @override
  Widget build(BuildContext context) {
    return _AnimatedStoryPane(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balmi의 약속',
              style: BalmiTheme.tracked(
                size: 11,
                color: BalmiColors.potatoDk,
                trackingEm: 0.14,
              ),
            ),
            const SizedBox(height: 18),
            const BalmiWordmark(height: 40),
            const SizedBox(height: 20),
            Text(
              BalmiCopy.onboardingStory4Title,
              style: BalmiTheme.body(size: 26, weight: FontWeight.w800, height: 1.28),
            ),
            const SizedBox(height: 16),
            Text(
              BalmiCopy.onboardingStory4Body,
              style: BalmiTheme.body(
                size: 15,
                weight: FontWeight.w600,
                height: 1.55,
                color: BalmiColors.ink.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              BalmiCopy.slogan,
              style: BalmiTheme.body(
                size: 14,
                weight: FontWeight.w700,
                height: 1.45,
                color: BalmiColors.potatoDk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              BalmiCopy.heroLine,
              style: BalmiTheme.body(size: 13, color: BalmiColors.sub, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fade + slight upward slide when a story page enters the viewport.
class _AnimatedStoryPane extends StatefulWidget {
  const _AnimatedStoryPane({required this.child});

  final Widget child;

  @override
  State<_AnimatedStoryPane> createState() => _AnimatedStoryPaneState();
}

class _AnimatedStoryPaneState extends State<_AnimatedStoryPane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BalmiColors.potato.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BalmiColors.potato.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: BalmiTheme.tracked(
          size: 11,
          color: BalmiColors.potatoDk,
          trackingEm: 0.16,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: BalmiColors.mist,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: BalmiTheme.body(size: 12, weight: FontWeight.w700),
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
