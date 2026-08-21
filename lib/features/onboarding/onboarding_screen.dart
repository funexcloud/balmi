import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/copy.dart';
import '../../data/oem/battery_optimization.dart';
import '../../data/repositories/session_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;
  String _oem = '';
  bool _ignoring = false;

  @override
  void initState() {
    super.initState();
    _loadOem();
  }

  Future<void> _loadOem() async {
    final m = await OemBattery.manufacturer();
    final ignoring = await OemBattery.isIgnoringOptimizations();
    if (!mounted) return;
    setState(() {
      _oem = OemBattery.familyLabel(m);
      _ignoring = ignoring;
    });
  }

  Future<void> _next() async {
    if (_index < 3) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _pageBody(
                    title: BalmiCopy.onboardingWelcome,
                    body: '${BalmiCopy.oneLiner}\n\n${BalmiCopy.positioning}',
                  ),
                  _pageBody(
                    title: BalmiCopy.onboardingTrustTitle,
                    body: BalmiCopy.trustAlways,
                  ),
                  _permsPage(),
                  _batteryPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: _next,
                child: Text(_index < 3 ? BalmiCopy.continueLabel : BalmiCopy.done),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBody({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            BalmiCopy.appName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text(body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _permsPage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(BalmiCopy.onboardingPermsTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(BalmiCopy.trustAlways),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Permission.locationWhenInUse.request(),
            child: const Text(BalmiCopy.locationPermission),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await Permission.locationWhenInUse.request();
              await Permission.locationAlways.request();
            },
            child: const Text(BalmiCopy.alwaysLocation),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Permission.notification.request(),
            child: const Text(BalmiCopy.notificationPermission),
          ),
        ],
      ),
    );
  }

  Widget _batteryPage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(BalmiCopy.onboardingBatteryTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(BalmiCopy.onboardingBatteryBody),
          const SizedBox(height: 8),
          Text('감지된 기기: ${_oem.isEmpty ? '…' : _oem} · 최적화 제외 ${_ignoring ? '완료' : '필요'}'),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await OemBattery.requestIgnore();
              await _loadOem();
            },
            child: const Text(BalmiCopy.ignoreBattery),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await OemBattery.openOemSettings();
              await _loadOem();
            },
            child: Text('${BalmiCopy.oemSettings} ($_oem)'),
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
