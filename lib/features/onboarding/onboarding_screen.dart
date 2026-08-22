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
  String? _permHint;

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

  Future<bool> _locationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always ||
        p == LocationPermission.whileInUse;
  }

  Future<void> _next() async {
    setState(() => _permHint = null);
    if (_index == 2) {
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
    if (_index < 3) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    if (!await _locationReady()) {
      if (!mounted) return;
      setState(() => _permHint = BalmiCopy.permsRequired);
      return;
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BalmiWordmark(height: 28),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() {
                  _index = i;
                  _permHint = null;
                }),
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
            if (_permHint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  _permHint!,
                  style: BalmiTheme.body(
                    size: 13,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            SafePrimaryButton(
              label: _index < 3 ? BalmiCopy.continueLabel : BalmiCopy.done,
              onPressed: _next,
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
          const SizedBox(height: 16),
          Text(title, style: BalmiTheme.body(size: 26, weight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text(body, style: BalmiTheme.body(size: 16, height: 1.5)),
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
          Text(
            BalmiCopy.onboardingPermsTitle,
            style: BalmiTheme.body(size: 22, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(BalmiCopy.trustAlways, style: BalmiTheme.body(size: 14)),
          const SizedBox(height: 8),
          Text(BalmiCopy.permsRequired, style: BalmiTheme.body(size: 12, color: BalmiColors.sub)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Permission.locationWhenInUse.request(),
            child: const Text(BalmiCopy.locationPermission),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final whenInUse = await Permission.locationWhenInUse.request();
              if (!whenInUse.isGranted) return;
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
          Text(
            BalmiCopy.onboardingBatteryTitle,
            style: BalmiTheme.body(size: 22, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(BalmiCopy.onboardingBatteryBody, style: BalmiTheme.body(size: 15, height: 1.5)),
          const SizedBox(height: 8),
          Text(
            '감지된 기기: ${_oem.isEmpty ? '…' : _oem} · 최적화 제외 ${_ignoring ? '완료' : '필요'}',
            style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
          ),
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
